"""Safety checks use synthetic backup observations and mocked disk commands only."""

import importlib.util
import pathlib
import plistlib
import subprocess
import unittest
from unittest.mock import patch


MODULE = pathlib.Path(__file__).resolve().parents[1] / "modules/time_machine/backup.py"
SPEC = importlib.util.spec_from_file_location("backup", MODULE)
backup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backup)
DESTINATION = "destination-id"
VOLUME = "volume-uuid"


def observation(attempt=10, snapshot=20, result=0, running=False, target=False):
    return dict(attempt=attempt, snapshot=snapshot, result=result,
                running=running, targetRunning=target)


class BackupResultTests(unittest.TestCase):
    def setUp(self):
        self.observe = patch.object(backup, "observe").start()
        self.eject = patch.object(backup, "eject").start()
        self.addCleanup(patch.stopall)

    def check(self, current, state=None):
        self.observe.return_value = current
        return backup.check(DESTINATION, VOLUME, state or {})

    def finish(self, current, state):
        pending = self.check(current, state)
        self.assertNotIn("event", pending)
        return self.check(current, pending["state"])

    def test_startup_and_reload_ignore_old_success(self):
        old = observation()
        state = self.check(old)["state"]
        self.assertNotIn("event", self.check(old, state))
        self.assertNotIn("event", self.check(old, {}))
        self.eject.assert_not_called()

    def test_new_success_is_ejected_once_after_two_idle_checks(self):
        state = self.check(observation())["state"]
        complete = observation(attempt=30, snapshot=40)
        response = self.finish(complete, state)
        self.assertEqual(response["event"], "ejected")
        self.assertNotIn("event", self.check(complete, response["state"]))
        self.eject.assert_called_once_with(DESTINATION, VOLUME, complete)

    def test_backup_still_running_is_never_ejected(self):
        state = self.check(observation())["state"]
        current = observation(attempt=30, snapshot=40, running=True, target=True)
        for _ in range(3):
            state = self.check(current, state)["state"]
        self.eject.assert_not_called()

    def test_failure_cancellation_and_stale_success_keep_disk_connected(self):
        for result in (1, 2, -1, 0):
            with self.subTest(result=result):
                state = self.check(observation())["state"]
                response = self.finish(observation(attempt=30, snapshot=20, result=result), state)
                self.assertEqual(response["event"], "backupFailed")
                self.assertNotIn("event", self.check(
                    observation(attempt=30, snapshot=20, result=result), response["state"]))
        self.eject.assert_not_called()

    def test_new_snapshot_with_failed_result_is_not_success(self):
        state = self.check(observation())["state"]
        response = self.finish(observation(attempt=30, snapshot=40, result=2), state)
        self.assertEqual(response["event"], "backupFailed")
        self.eject.assert_not_called()

    def test_completion_during_sleep_without_observing_running(self):
        state = self.check(observation())["state"]
        self.assertEqual(self.finish(observation(attempt=30, snapshot=40), state)["event"], "ejected")

    def test_backup_already_running_at_startup_is_watched(self):
        state = self.check(observation(attempt=30, running=True, target=True))["state"]
        self.assertEqual(self.finish(observation(attempt=30, snapshot=40), state)["event"], "ejected")

    def test_observed_cancel_without_new_attempt_record_is_reported(self):
        state = self.check(observation(running=True, target=True))["state"]
        self.assertEqual(self.finish(observation(), state)["event"], "backupFailed")
        self.eject.assert_not_called()

    def test_busy_disk_is_not_retried(self):
        self.eject.side_effect = RuntimeError("Resource busy")
        state = self.check(observation())["state"]
        complete = observation(attempt=30, snapshot=40)
        response = self.finish(complete, state)
        self.assertEqual(response["event"], "ejectFailed")
        for _ in range(3):
            response = self.check(complete, response["state"])
            self.assertNotIn("event", response)
        self.eject.assert_called_once()

    def test_any_running_backup_resets_pending_idle_result(self):
        state = self.check(observation())["state"]
        complete = observation(attempt=30, snapshot=40)
        state = self.check(complete, state)["state"]
        state = self.check(observation(attempt=30, snapshot=40, running=True), state)["state"]
        self.assertNotIn("pending", state)
        self.assertNotIn("event", self.check(complete, state))
        self.eject.assert_not_called()

    def test_result_updates_restart_idle_confirmation(self):
        state = self.check(observation())["state"]
        state = self.check(observation(attempt=30, snapshot=20), state)["state"]
        response = self.check(observation(attempt=30, snapshot=40), state)
        self.assertNotIn("event", response)
        self.eject.assert_not_called()

    def test_first_backup_without_prior_snapshot(self):
        state = self.check(observation(attempt=0, snapshot=0, result=-1))["state"]
        self.assertEqual(self.finish(observation(attempt=30, snapshot=40), state)["event"], "ejected")


class DiskSafetyTests(unittest.TestCase):
    def setUp(self):
        self.volume = dict(VolumeUUID=VOLUME, Internal=False, MountPoint="/Volumes/backup",
                           FilesystemType="apfs", APFSPhysicalStores=[{"APFSPhysicalStore": "disk6s2"}])
        self.disk = dict(DeviceIdentifier="disk6", DeviceTreePath="usb-device-path",
                         WholeDisk=True, Internal=False, VirtualOrPhysical="Physical", Ejectable=True)

    def test_resolve_external_physical_disk_through_apfs_store(self):
        with patch.object(backup, "disk_info", side_effect=[
                self.volume, {"ParentWholeDisk": "disk6"}, self.disk]) as info:
            self.assertEqual(backup.resolve_disk(VOLUME), self.disk)
            self.assertEqual([call.args[0] for call in info.call_args_list], [VOLUME, "disk6s2", "disk6"])

    def test_wrong_volume_internal_disk_and_multiple_stores_are_rejected(self):
        variants = [dict(VolumeUUID="other"), dict(Internal=True), dict(MountPoint=""),
                    dict(APFSPhysicalStores=[{}, {}])]
        for variant in variants:
            with self.subTest(variant=variant), patch.object(
                    backup, "disk_info", return_value=dict(self.volume, **variant)):
                with self.assertRaises(RuntimeError):
                    backup.resolve_disk(VOLUME)
        with patch.object(backup, "disk_info", side_effect=[
                self.volume, {"ParentWholeDisk": "disk0"}, dict(self.disk, Internal=True)]):
            with self.assertRaises(RuntimeError):
                backup.resolve_disk(VOLUME)

    def test_new_backup_or_identity_change_blocks_eject(self):
        for current in (observation(attempt=30, snapshot=40, running=True),
                        observation(attempt=50, snapshot=40)):
            with patch.object(backup, "resolve_disk", return_value=self.disk), patch.object(
                    backup, "observe", return_value=current), patch.object(backup, "run") as run:
                with self.assertRaises(RuntimeError):
                    backup.eject(DESTINATION, VOLUME, observation(attempt=30, snapshot=40))
                run.assert_not_called()
        with patch.object(backup, "resolve_disk", side_effect=[
                self.disk, dict(self.disk, DeviceTreePath="another-device")]), patch.object(backup, "run") as run:
            with self.assertRaises(RuntimeError):
                backup.eject(DESTINATION, VOLUME, observation())
            run.assert_not_called()

    def test_eject_command_has_no_force(self):
        with patch.object(backup, "resolve_disk", return_value=self.disk), patch.object(
                backup, "observe", return_value=observation()), patch.object(
                backup, "run", return_value=b"Disk disk6 ejected") as run:
            backup.eject(DESTINATION, VOLUME, observation())
            self.assertEqual(run.call_args_list[0].args[0], [backup.DISKUTIL, "eject", "disk6"])

    def test_native_eject_failure_is_preserved(self):
        with patch.object(backup, "resolve_disk", return_value=self.disk), patch.object(
                backup, "observe", return_value=observation()), patch.object(
                backup, "run", side_effect=RuntimeError("Resource busy")) as run:
            with self.assertRaisesRegex(RuntimeError, "Resource busy"):
                backup.eject(DESTINATION, VOLUME, observation())
            run.assert_called_once_with([backup.DISKUTIL, "eject", "disk6"], timeout=90)

    def test_unreadable_status_cannot_be_treated_as_idle(self):
        preferences = {"Destinations": [{
            "DestinationID": DESTINATION, "DestinationUUIDs": [VOLUME]}]}
        with patch.object(backup, "run", side_effect=[plistlib.dumps(preferences), plistlib.dumps({})]):
            with self.assertRaises(RuntimeError):
                backup.observe(DESTINATION, VOLUME)

    def test_successful_eject_does_not_require_disappearing_device_record(self):
        with patch.object(backup, "resolve_disk", return_value=self.disk), patch.object(
                backup, "observe", return_value=observation()), patch.object(
                backup, "run", side_effect=[b"Disk disk6 ejected",
                                            plistlib.dumps({"AllDisks": ["disk6"]})]) as run:
            backup.eject(DESTINATION, VOLUME, observation())
            run.assert_called_once_with([backup.DISKUTIL, "eject", "disk6"], timeout=90)


if __name__ == "__main__":
    unittest.main()
