c.NotebookApp.open_browser = False
c.NotebookApp.ip='0.0.0.0' #'*'
c.NotebookApp.port = 8192 # If you change the port here, make sure you update it in the jupyter_installer.sh file as well
#Is now: tdeboer-ilmn
c.NotebookApp.password = u'sha1:6ccbd197847ec7a0780ea689a2161fbb620ecbdb'
c.Authenticator.admin_users = {'jupyter'}
c.LocalAuthenticator.create_system_users = True
