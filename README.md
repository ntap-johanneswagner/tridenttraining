# :trident: Trident Training

# Introduction
You will work in the NetApp Lab on Demand environment, but we`ve prepared some more resources for you than the typical lab guide offers. A special thanks to our dear trusted colleague Yves Weisser (https://github.com/YvosOnTheHub) who created a lot of the code we are using in this lab. Before you can start, there are some preparations to do.

You will connect to a Linux jumphost from which you can access the training environment.
It will provide you two K8s clusters (rke1, rke2), two ONTAP Clusters, Trident with preconfigured backend and a preconfigured nas storageclass.  
Usefull things to know:

You can switch between the K8s clusters by simply using the alias _rke1_ and _rke2_. They will automatically run the export command for the specific kubeconfig of each cluster. If you want to do that manually, you can use the following:
rke1
```console
export KUBECONFIG=/home/user/kubeconfigs/rke1/kube_config_cluster.yml
```
rke2
```console
export KUBECONFIG=/home/user/kubeconfigs/rke2/kube_config_cluster.yml
```

## Prework

1. Access the lab environment:  
https://lod-bootcamp.netapp.com  
<span style="color:red">Please ignore the Lab Guide that is provided there and use this one</span>

2. Request the lab *Cloud-native Applications with Astra Control Center v1.4* and connect to the jumphost 

3. Open a terminal    

4. We've prepared some exercises for you that are hosted in a github repo. To have them available on your training environment, please create a directory, enter it and clone the repo with the following commands:  
```console
cd /home/user
git clone https://github.com/ntap-johanneswagner/tridenttraining
```

You should now have several directories available. The lab is structured with different scenarios. Everything you need is placed in a folder with the same name. 

We split the lab into multiple parts:

[Part 1 - Storage in Kubernetes  - Overview](Part1.md)

[Part 2 - Storage in Kubernetes - Deep-dive](Part2.md)

[Part 3 - Snapshots & Clones, Consumption Control](Part3.md)

[Part4 - Backup & Restore with Astra Control](Part4.md)


