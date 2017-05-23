import subprocess
tunnelToFTP = "ssh -f -L 7080:192.168.0.3:22 superuser@10.0.0.131 -N"
tunnelToManager = "ssh -f -L 8080:192.168.0.2:22 superuser@10.0.0.131 -N"

def run_script(script, stdin=None):
	try:
		proc = subprocess.Popen(['bash', '-c', script])
		proc.communicate()
		if proc.returncode:
			raise Exception
	except Exception:
		print "Couldn't create tunnel"

print "#####|Creating tunnel to FTP Server on port 7080|#####"
run_script(tunnelToFTP)

print "#####|Creating tunnel to Manager Server on port 8080|#####"
run_script(tunnelToManager)
