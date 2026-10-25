"""Kill the actual Swift journal writer; reopen it in a fresh process."""
import pathlib
import signal
import subprocess
import sys
import tempfile

binary = str(pathlib.Path(sys.argv[1]).resolve())
fixture = pathlib.Path(__file__).parent / 'OfflineCryptoTests/Fixtures/responses.json'
with tempfile.TemporaryDirectory(prefix='ypso-crash-') as directory:
    def run(mode, database, expected, output=None):
        result = subprocess.run([binary, mode, str(database), str(fixture)], capture_output=True, text=True, timeout=10)
        if result.returncode != expected or (output is not None and result.stdout.strip() != output):
            raise AssertionError((mode, result.returncode, result.stdout, result.stderr))

    for mode in ('kill-before', 'kill-after'):
        database = pathlib.Path(directory) / (mode + '.sqlite')
        run('initialize', database, 0)
        run(mode, database, -signal.SIGKILL, '')
        if mode == 'kill-before':
            run('accept', database, 0, 'accepted')
        run('accept', database, 23, 'replay')
print('PASS: SIGKILL before COMMIT recovers; SIGKILL after COMMIT rejects replay')
