c.NotebookApp.open_browser = False
c.NotebookApp.ip='0.0.0.0' #'*'
c.NotebookApp.port = 8192 # If you change the port here, make sure you update it in the jupyter_installer.sh file as well
#Is now: tdeboer-ilmn
c.NotebookApp.password = u'sha1:46f4acd93b153529a950de65e4da0d83684998c6'
c.Authenticator.admin_users = {'jupyter'}
c.LocalAuthenticator.create_system_users = True
