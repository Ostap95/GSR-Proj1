import subprocess
tunnelToFTP_DNS1 = "ssh -f -L 7080:192.168.0.3:22 superuser@10.0.0.131 -N"
tunnelToManager_DNS1 = "ssh -f -L 7085:192.168.0.2:22 superuser@10.0.0.131 -N"
tunnelToFTP_DNS2 = "ssh -f -L 7090:192.168.0.3:22 superuser@10.0.0.130 -N"
tunnelToManager_DNS2 = "ssh -f -L 7095:192.168.0.2:22 superuser@10.0.0.130 -N"
tunnelToFTP_Proxy = "ssh -f -L 7100:192.168.0.3:22 superuser@10.0.0.132 -N"
tunnelToManager_Proxy = "ssh -f -L 7105:192.168.0.2:22 superuser@10.0.0.132 -N"

def run_script(script, stdin=None):
	try:
		proc = subprocess.Popen(['bash', '-c', script])
		proc.communicate()
		if proc.returncode:
			raise Exception
	except Exception:
		print "Couldn't create tunnel"

print "#####|Creating tunnel to FTP Server on port 7080 with Primary DNS Server|#####"
run_script(tunnelToFTP_DNS1)

print "#####|Creating tunnel to Manager Server on port 7085 with Primary DNS Server|#####"
run_script(tunnelToManager_DNS1)

print "#####|Creating tunnel to FTP Server on port 7090 with Secondary DNS Server|#####"
run_script(tunnelToFTP_DNS2)

print "#####|Creating tunnel to Manager Server on port 7095 with Secondary DNS Server|#####"
run_script(tunnelToManager_DNS2)

print "#####|Creating tunnel to FTP Server on port 7100 with Proxy Server|#####"
run_script(tunnelToFTP_Proxy)

print "#####|Creating tunnel to Manager Server on port 7105 with Proxy Server|#####"
run_script(tunnelToManager_Proxy)

