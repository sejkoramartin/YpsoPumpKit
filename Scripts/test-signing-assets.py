import copy
import datetime
import importlib.util
import unittest
from pathlib import Path
spec = importlib.util.spec_from_file_location('assets', Path(__file__).with_name('prepare-trio-signing-assets.py'))
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)

class ProfileValidationTests(unittest.TestCase):
    def setUp(self):
        self.team = 'ABCDEFGHIJ'
        self.bundle = 'org.ypsopumpkit.ABCDEFGHIJ.trio.sim'
        self.profile = {'TeamIdentifier': [self.team],
                        'Entitlements': {'application-identifier': self.team + '.' + self.bundle, 'get-task-allow': False},
                        'ExpirationDate': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1),
                        'UUID': '12345678-1234-1234-1234-123456789abc'}
    def test_distribution_profile(self):
        assets.validate(self.profile, self.team, self.bundle)
    def test_wrong_identity(self):
        for team, bundle in [('ZZZZZZZZZZ', self.bundle), (self.team, 'org.other.app')]:
            with self.assertRaises(ValueError):
                assets.validate(self.profile, team, bundle)
    def test_development_adhoc_and_enterprise_rejected(self):
        for key, value in [('ProvisionedDevices', ['device']), ('ProvisionsAllDevices', True)]:
            profile = copy.deepcopy(self.profile)
            profile[key] = value
            with self.assertRaises(ValueError):
                assets.validate(profile, self.team, self.bundle)
        self.profile['Entitlements']['get-task-allow'] = True
        with self.assertRaises(ValueError):
            assets.validate(self.profile, self.team, self.bundle)
    def test_expired(self):
        self.profile['ExpirationDate'] = datetime.datetime(2000, 1, 1)
        with self.assertRaises(ValueError):
            assets.validate(self.profile, self.team, self.bundle)
    def test_invalid_uuid(self):
        self.profile['UUID'] = '../../other-file'
        with self.assertRaises(ValueError):
            assets.validate(self.profile, self.team, self.bundle)

if __name__ == '__main__':
    unittest.main()
