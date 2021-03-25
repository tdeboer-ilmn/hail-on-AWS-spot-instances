c.NotebookApp.open_browser = False
c.NotebookApp.ip='0.0.0.0' #'*'
c.NotebookApp.port = 8192 # If you change the port here, make sure you update it in the jupyter_installer.sh file as well
#Is now: tdeboer-ilmn
#Created with
# from notebook.auth import passwd
# passwd(algorithm='sha1')
c.NotebookApp.password = u'sha1:fd9cac42d6b4:aa89914827e5fabf77633ce74686ffd409ceb6b5'
c.Authenticator.admin_users = {'jupyter'}
c.LocalAuthenticator.create_system_users = True
