pipeline {
    agent any
    tools {
        "org.jenkinsci.plugins.terraform.TerraformInstallation" "terraform"
    }

    environment {
        TF_HOME = tool('terraform')
        TF_INPUT = "0"
        TF_IN_AUTOMATION = "TRUE"
        TF_VAR_vault_token = credentials('Vault')
        TF_VAR_vsphere_datacenter = "Amsterdam"
        TF_VAR_vsphere_datastore = "HX-ACI" 
        TF_VAR_vsphere_resource_pool = "HX-ACI/Resources"
        TF_VAR_vsphere_folder = "PVT-EMEAR"
        TF_VAR_vsphere_vm_portgroup = "vm-network-98"
        TF_VAR_vsphere_vm_name = "vm-app-prod"
        TF_VAR_vsphere_vm_template = "Ubuntu Workstation ACI"
        TF_VAR_vault_address = "https://emear-secrets.cisco.com"
        PATH = "$TF_HOME:$PATH"
        AWS_ACCESS_KEY_ID = credentials('Aws Access Key')
        AWS_SECRET_ACCESS_KEY = credentials('Aws Secret Key')
    }

    stages {
        stage('Initialization'){
            steps {
                dir('.'){
	                sh '''
			terraform --version
			outofdate=`terraform  --version | { grep "out of date!" || true; }`
			if [ -n "$outofdate" ]; then 
				cd $TF_HOME
				wget -q -O tf.zip https://releases.hashicorp.com/terraform/0.15.1/terraform_0.15.1_linux_amd64.zip && unzip -o tf.zip && rm tf.zip 
			fi
			terraform --version
'''
			sh "terraform init"
                }
            }
        }
        stage('Config Validation'){
            steps {
                dir('.'){
                    sh 'terraform validate'
                }
            }
        }
        stage('Build Plan'){
            steps {
                dir('.'){
                    script {
                        sh "terraform plan -out pvt21demo-plan.tfplan;echo \$? > status"
                        stash name: "pvt21demo-plan", includes: "pvt21demo-plan.tfplan"
                    }
                }
            }
        }
        stage('Create Virtual Machine'){
            steps {
                script{
                    def apply = false
                    try {
                        input message: 'confirm apply', ok: 'Apply Config'
                        apply = true
                    } catch (err) {
                        apply = false
                        dir('.'){
                            sh "terraform destroy -auto-approve"
                        }
                        currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('.'){
                            unstash "pvt21demo-plan"
                            sh 'terraform apply pvt21demo-plan.tfplan'
                        }
                    }
                }
            }
        }
    }
}
