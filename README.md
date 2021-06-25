1. vars.tf file has some default values defined, so it will run with no issues out of the box. If you want to 
   override the default values and set your own ones - either do it directly in the file, or execute plan-apply-destroy
   using the following syntax:

   terraform apply -var var_name1=value -var var_name2=value

   There are two variables that contain sensitive data - admin_username and admin_password. They are defined in 
   secret.tfvars file. Just change the placeholders to the values you need and then run plan-apply-destroy using the following syntax:

   terraform apply -var-file="your_file" (with the double quotes)

   Do not store .tfvars file in the version control, always include it in the .gitignore or use alternative methods to manage the secrets.

   Default count of the instances is set to 3 using instance_count variable. Change it in the file itself, or use the syntax from the first paragraph to override it with the -var argument.

2. postInstall.ps1 script is used to install winRAR, after that Windows updates are installed with
   Install-WindowsUpdate (which is using -AutoReboot). 
   Script is passed to the host as a base64 encoded string and then executed via FirstLogonCommands.xml.
   When you connect to the VM, it may still be running the installation of Windows updates, since there's no
   retry-catch logic to this solution - Terraform doesn't wait until the script is executed and throws 
   'Apply complete!', even though the execution is still in progress and VM has not been yet restarted.
   VM will restart and you will be able to connect with no issues.

3. Output is configured to show the public IPs of the machines that can be used to connect via RDP.
   The IPs are shown in the command line output, so if you want your outputs to be stored in the file,
   just run terraform output > file.txt. This will include all the outputs you configured in the file.

