# Extra live checks for the older check.py runner. The authoritative checks are in validation/.
import subprocess
result = subprocess.run(['bash', str(DIRECTORY.parent / 'validate.sh')], capture_output=True, text=True, timeout=300)
assert result.returncode == 0, 'validation scripts failed: ' + result.stdout
