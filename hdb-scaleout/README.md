# HANA Scale-Out deployment on Azure with Azure NetAPP Files
The template currently deploys three HANA Virtual machines with one managed disk attached.

## **Deployment options and Supported operating systems**

You can use the scripts to deploy environments for both development, test, quality assurance and production workloads.
- Suse
- RedHat

### **Architectural Diagram**

![Deployment Architecture](HANA-Scale-Out-with-StandBy-ANF.png)


## **Deploy on Azure**

#### **network.json**

This is the template for the VNET, Subnet and Network Security Group deployment.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fprasroy%2Fhanaonazurearm%2Fmaster%2Fhdb-scaleout%2Fnetwork.json)

#### **anfdeploy.json**

This is the template for ANF deployment.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fprasroy%2Fhanaonazurearm%2Fmaster%2Fhdb-scaleout%2Fanfdeploy.json)

#### **infrastructure.json**
This is the template for the compute and storage deployment.

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fprasroy%2Fhanaonazurearm%2Fmaster%2Fhdb-scaleout%2Fhdb-scaleout.json)