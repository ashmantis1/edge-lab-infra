# Requirements
Before running the playbook, make sure you have all the necessary requirements. You can do this by running: 

`ansible-galaxy install -r requirements.yaml` 

You will then need to fill out all the required variables, found in `ansible/inventory/group_vars/all/vars.yaml`

# Running the playbook 

From the root of the freeipa directory, run: 

`ansible-playbook -i ansible/inventory/inventory.ini deploy.yaml`

