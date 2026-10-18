"""Observe Time Machine and safely eject one explicitly configured backup disk."""

import argparse
import datetime
import json
import plistlib
import signal
import subprocess
import sys


PREFERENCES = "/Library/Preferences/com.apple.TimeMachine"
DEFAULTS = "/usr/bin/defaults"
TMUTIL = "/usr/bin/tmutil"
DISKUTIL = "/usr/sbin/diskutil"


def run(arguments, timeout=15):
    # Also reap the child if Hammerspoon stops this task during a reload.
    process = subprocess.Popen(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        if process.returncode:
            raise RuntimeError(stderr.decode(errors="replace").strip()
                               or stdout.decode(errors="replace").strip()
                               or "命令执行失败: " + arguments[0])
        return stdout
    finally:
        if process.poll() is None:
            process.kill()
            process.communicate()


def newest_date(values):
    dates = [value.replace(tzinfo=datetime.timezone.utc).timestamp()
             for value in values if isinstance(value, datetime.datetime)]
    return max(dates) if dates else 0


def observe(destination_id, volume_uuid):
    # Use the preferences service: direct file reads require Full Disk Access in Hammerspoon.
    preferences = plistlib.loads(run([DEFAULTS, "export", PREFERENCES, "-"]))
    destinations = [item for item in preferences.get("Destinations", [])
                    if item.get("DestinationID") == destination_id
                    and volume_uuid in item.get("DestinationUUIDs", [])]
    if len(destinations) != 1:
        raise RuntimeError("找不到与配置身份匹配的 Time Machine 目标；未执行弹出")
    destination = destinations[0]
    status = plistlib.loads(run([TMUTIL, "status", "-X"]))
    if status.get("Running") not in (True, False, 0, 1):
        raise RuntimeError("无法确定 Time Machine 是否仍在运行；未执行弹出")
    result = destination.get("RESULT")
    return {
        "attempt": newest_date(destination.get("AttemptDates", [])),
        "snapshot": newest_date(destination.get("SnapshotDates", [])),
        "result": result if type(result) is int else -1,
        "running": bool(status["Running"]),
        "targetRunning": bool(status["Running"])
        and status.get("DestinationID") == destination_id,
    }


def disk_info(device):
    return plistlib.loads(run([DISKUTIL, "info", "-plist", device]))


def resolve_disk(volume_uuid):
    volume = disk_info(volume_uuid)
    if (volume.get("VolumeUUID") != volume_uuid
            or volume.get("Internal") is not False
            or not volume.get("MountPoint")
            or volume.get("FilesystemType") != "apfs"):
        raise RuntimeError("备份卷未挂载或身份不符；未执行弹出")
    stores = volume.get("APFSPhysicalStores", [])
    if len(stores) != 1:
        raise RuntimeError("备份卷未对应唯一物理存储；未执行弹出")
    partition = disk_info(stores[0]["APFSPhysicalStore"])
    disk = disk_info(partition["ParentWholeDisk"])
    if (disk.get("WholeDisk") is not True or disk.get("Internal") is not False
            or disk.get("VirtualOrPhysical") != "Physical"
            or not disk.get("Ejectable") or not disk.get("DeviceTreePath")):
        raise RuntimeError("目标不是可安全弹出的外置物理硬盘；未执行弹出")
    return disk


def result_key(observation):
    return [observation["attempt"], observation["snapshot"], observation["result"]]


def eject(destination_id, volume_uuid, expected):
    disk = resolve_disk(volume_uuid)
    # Resolve the stable UUID again, then recheck the backup immediately before eject.
    confirmed = resolve_disk(volume_uuid)
    if (confirmed["DeviceIdentifier"] != disk["DeviceIdentifier"]
            or confirmed["DeviceTreePath"] != disk["DeviceTreePath"]):
        raise RuntimeError("备份硬盘连接已变化；未执行弹出")
    current = observe(destination_id, volume_uuid)
    if current["running"] or result_key(current) != result_key(expected):
        raise RuntimeError("备份状态已变化；未执行弹出")
    run([DISKUTIL, "eject", disk["DeviceIdentifier"]], timeout=90)
    # The physical device must be offline, rather than merely its backup volume.
    disks = plistlib.loads(run([DISKUTIL, "list", "-plist"]))
    if disk["DeviceIdentifier"] in disks.get("AllDisks", []):
        raise RuntimeError("系统尚未确认整块硬盘退出，请先检查硬盘状态再拔线")


def check(destination_id, volume_uuid, state):
    observation = observe(destination_id, volume_uuid)
    if not state:
        return {"state": {
            "attempt": observation["attempt"],
            "snapshot": observation["snapshot"],
            "active": observation["targetRunning"],
        }}

    state = dict(state)
    if observation["running"]:
        state["active"] = state.get("active", False) or observation["targetRunning"]
        state.pop("pending", None)
        return {"state": state}

    changed = (observation["attempt"] != state["attempt"]
               or observation["snapshot"] != state["snapshot"])
    if not changed and not state.get("active"):
        return {"state": state}

    # Wait for two identical idle observations so backupd can finish publishing its result.
    key = result_key(observation)
    if state.get("pending") != key:
        state["pending"] = key
        return {"state": state}

    previous_snapshot = state["snapshot"]
    state.update(attempt=observation["attempt"], snapshot=observation["snapshot"], active=False)
    state.pop("pending", None)
    snapshot, attempt = observation["snapshot"], observation["attempt"]
    success = (observation["result"] == 0 and attempt > 0 and snapshot > 0
               and snapshot >= attempt
               and snapshot > previous_snapshot)
    if not success:
        return {"state": state, "event": "backupFailed",
                "message": "备份失败、已取消或无法确认成功；硬盘保持连接。请检查 Time Machine。"}
    try:
        eject(destination_id, volume_uuid, observation)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        # Consume this result even on refusal: never repeatedly try to eject a busy disk.
        return {"state": state, "event": "ejectFailed",
                "message": "备份已完成，但未能确认整盘安全弹出，请检查后再拔线。",
                "detail": str(error)}
    return {"state": state, "event": "ejected",
            "message": "备份完成，硬盘已安全弹出，可以拔线"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", required=True)
    parser.add_argument("--volume", required=True)
    parser.add_argument("--state", default="{}")
    arguments = parser.parse_args()
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(1))
    try:
        response = check(arguments.destination, arguments.volume, json.loads(arguments.state))
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(json.dumps(response, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
