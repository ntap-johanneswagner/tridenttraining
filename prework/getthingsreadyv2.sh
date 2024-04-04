#!/bin/bash
# SCRIPT TO RUN ON HELPER1

echo "############################"
echo "# start upgrade to 23.10:"; date
echo "############################"

cd

echo
echo "##############################################"
echo "# Making space: Remove old container images"
echo "##############################################"
podman images | grep localhost | awk '{print $1":"$2}' | xargs podman image rm
podman images | grep registry | awk '{print $1":"$2}' | xargs podman image rm
podman images | grep docker | awk '{print $1":"$2}' | xargs podman image rm

echo
echo "######################################"
echo "# Making space: Remove old packages"
echo "######################################"
rm -f ~/tarballs/astra-control-center-*.tar.gz
rm -f ~/tarballs/trident-installer-21*.tar.gz
rm -f ~/tarballs/trident-installer-22*.tar.gz
rm -rf ~/acc/images

echo
echo "##########################"
echo "# download ACC package"
echo "##########################"
mv ~/acc ~/acc_23.07
wget https://netapp-my.sharepoint.com/:u:/p/yweisser/EXti08LgIdpBtiRsco352V8BM3Ni5TAdoVdt2tkTQ2chlw?download=1  -O ~/tarballs/astra-control-center-23.10.0-68.tar.gz

packsize=$(du --apparent-size --block-size=1 ~/tarballs/astra-control-center-23.10.0-68.tar.gz | awk '{ print $1}')
if [ $packsize -lt 10000000 ]; then
  echo "Seems like the OneDrive link is not valid anymore... Ask Yvos to renew the share !"
  echo "When the link is updated, you can restart the script"
  exit
fi

tar -zxvf ~/tarballs/astra-control-center-23.10.0-68.tar.gz

echo
echo "##########################"
echo "# add images to local repo"
echo "##########################"
podman login -u registryuser -p Netapp1! registry.demo.netapp.com

export REGISTRY=registry.demo.netapp.com
export PACKAGENAME=acc
export PACKAGEVERSION=23.10.0-68
export DIRECTORYNAME=acc

for astraImageFile in $(ls ${DIRECTORYNAME}/images/*.tar) ; do
  # Load to local cache
  astraImage=$(podman load --input ${astraImageFile} | sed 's/Loaded image: //')
  # Remove path and keep imageName.
  astraImageNoPath=$(echo ${astraImage} | sed 's:.*/::')
  # Tag with local image repo.
  podman tag ${astraImage} ${REGISTRY}/netapp/astra/${PACKAGENAME}/${PACKAGEVERSION}/${astraImageNoPath}
  # podman tag ${astraImageNoPath} ${REGISTRY}/${astraImageNoPath}
  # Push to the local repo.
  podman push ${REGISTRY}/netapp/astra/${PACKAGENAME}/${PACKAGEVERSION}/${astraImageNoPath}
  # podman push ${REGISTRY}/${astraImageNoPath}
done

echo
echo "######################################"
echo "# install the updated ACC operator"
echo "######################################"
export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml
cd acc/manifests
cp astra_control_center_operator_deploy.yaml astra_control_center_operator_deploy.yaml.bak
sed -i s,ASTRA_IMAGE_REGISTRY,$REGISTRY/netapp/astra/$PACKAGENAME/$PACKAGEVERSION, astra_control_center_operator_deploy.yaml
sed -i s,ACCOP_HELM_INSTALLTIMEOUT,ACCOP_HELM_UPGRADETIMEOUT, astra_control_center_operator_deploy.yaml
sed -i s,'value: 5m','value: 300m', astra_control_center_operator_deploy.yaml
sed -i 's/imagePullSecrets: \[]/imagePullSecrets:/' astra_control_center_operator_deploy.yaml
sed -i '/imagePullSecrets/a \ \ \ \ \ \ - name: astra-registry-cred' astra_control_center_operator_deploy.yaml
kubectl apply -f astra_control_center_operator_deploy.yaml
sleep 20

echo
frames="/ | \\ -"
PODNAME=$(kubectl -n netapp-acc-operator get pod -o name)
until [[ $(kubectl -n netapp-acc-operator get $PODNAME -o=jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}') == 'True' ]]; do
    for frame in $frames; do
    sleep 1; printf "\rwaiting for the ACC Operator to be fully ready $frame"
    done
done
sleep 30

echo
echo "############################"
echo "# upgrade ACC to 23.10"
echo "############################"
kubectl -n netapp-acc patch acc/astra --type=json -p='[ 
    {"op":"add", "path":"/spec/crds", "value":{"shouldUpgrade": true}},
    {"op":"add", "path":"/spec/additionalValues/nautilus", "value":{"startupProbe": {"failureThreshold":600, "periodSeconds": 30}}},
    {"op":"add", "path":"/spec/additionalValues/polaris-keycloak", "value":{"livenessProbe":{"initialDelaySeconds":180},"readinessProbe":{"initialDelaySeconds":180}}},    
    {"op":"replace", "path":"/spec/imageRegistry/name","value":"registry.demo.netapp.com/netapp/astra/acc/23.10.0-68"},
    {"op":"replace", "path":"/spec/astraVersion","value":"23.10.0-68"}
]'
sleep 60

echo
frames="/ | \\ -"
until [[ $(kubectl -n netapp-acc get astracontrolcenters.astra.netapp.io astra -o=jsonpath='{.status.conditions[?(@.type=="Upgrading")].reason}') == 'Complete' ]]; do
    for frame in $frames; do
       sleep 1; printf "\rwaiting for ACC upgrade to be complete $frame"
    done
done

echo
echo "############################"
echo "# upgrade to 23.10 finished on:"; date
echo "############################"


echo "############################"
echo "# start upgrade to 24.02:"; date
echo "############################"

cd

echo
echo "###############################################"
echo "# Making space: Remove old container images"
echo "###############################################"
podman images | grep localhost | awk '{print $1":"$2}' | xargs podman image rm
podman images | grep registry | awk '{print $1":"$2}' | xargs podman image rm

echo
echo "######################################"
echo "# Making space: Remove old packages"
echo "######################################"
rm -f ~/tarballs/astra-control-center-*.tar.gz
rm -f ~/tarballs/trident-*.tar.gz
rm -rf ~/acc/images

echo
echo "##########################"
echo "# download ACC package"
echo "##########################"
mv ~/acc ~/acc_23.10
wget https://netapp-my.sharepoint.com/:u:/p/yweisser/EVY7z7C-COFEpNN1qemW51UBtDw_23BDV-JcBB26b1BOZg?download=1  -O ~/tarballs/astra-control-center-24.02.0-69.tar.gz

packsize=$(du --apparent-size --block-size=1 ~/tarballs/astra-control-center-24.02.0-69.tar.gz | awk '{ print $1}')
if [ $packsize -lt 10000000 ]; then
  echo "Seems like the OneDrive link is not valid anymore... Ask Yvos to renew the share !"
  echo "When the link is updated, you can restart the script"
  exit
fi

tar -zxvf ~/tarballs/astra-control-center-24.02.0-69.tar.gz

echo
echo "##########################"
echo "# add images to local repo"
echo "##########################"
podman login -u registryuser -p Netapp1! registry.demo.netapp.com

export REGISTRY=registry.demo.netapp.com
export PACKAGENAME=acc
export PACKAGEVERSION=24.02.0-69
export DIRECTORYNAME=acc

for astraImageFile in $(ls ${DIRECTORYNAME}/images/*.tar) ; do
  # Load to local cache
  astraImage=$(podman load --input ${astraImageFile} | sed 's/Loaded image: //')
  # Remove path and keep imageName.
  astraImageNoPath=$(echo ${astraImage} | sed 's:.*/::')
  # Tag with local image repo.
  podman tag ${astraImage} ${REGISTRY}/netapp/astra/${PACKAGENAME}/${PACKAGEVERSION}/${astraImageNoPath}
  # podman tag ${astraImageNoPath} ${REGISTRY}/${astraImageNoPath}
  # Push to the local repo.
  podman push ${REGISTRY}/netapp/astra/${PACKAGENAME}/${PACKAGEVERSION}/${astraImageNoPath}
  # podman push ${REGISTRY}/${astraImageNoPath}
done

echo
echo "######################################"
echo "# install the updated ACC operator"
echo "######################################"
export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml
cd acc/manifests
cp astra_control_center_operator_deploy.yaml astra_control_center_operator_deploy.yaml.bak
sed -i s,ASTRA_IMAGE_REGISTRY,$REGISTRY/netapp/astra/$PACKAGENAME/$PACKAGEVERSION, astra_control_center_operator_deploy.yaml
sed -i s,ACCOP_HELM_INSTALLTIMEOUT,ACCOP_HELM_UPGRADETIMEOUT, astra_control_center_operator_deploy.yaml
sed -i s,'value: 5m','value: 300m', astra_control_center_operator_deploy.yaml
sed -i 's/imagePullSecrets: \[]/imagePullSecrets:/' astra_control_center_operator_deploy.yaml
sed -i '/imagePullSecrets/a \ \ \ \ \ \ - name: astra-registry-cred' astra_control_center_operator_deploy.yaml
kubectl apply -f astra_control_center_operator_deploy.yaml
sleep 20

echo
frames="/ | \\ -"
PODNAME=$(kubectl -n netapp-acc-operator get pod -o name)
until [[ $(kubectl -n netapp-acc-operator get $PODNAME -o=jsonpath='{.status.conditions[?(@.type=="ContainersReady")].status}') == 'True' ]]; do
    for frame in $frames; do
    sleep 1; printf "\rwaiting for the ACC Operator to be fully ready $frame"
    done
done
sleep 30

echo
echo "############################"
echo "# upgrade ACC to 24.02"
echo "############################"
kubectl -n netapp-acc patch acc/astra --type=json -p='[ 
    {"op":"add", "path":"/spec/crds", "value":{"shouldUpgrade": true}},
    {"op":"add", "path":"/spec/additionalValues/nautilus", "value":{"startupProbe": {"failureThreshold":600, "periodSeconds": 30}}},
    {"op":"add", "path":"/spec/additionalValues/polaris-keycloak", "value":{"livenessProbe":{"initialDelaySeconds":180},"readinessProbe":{"initialDelaySeconds":180}}},    
    {"op":"replace", "path":"/spec/imageRegistry/name","value":"registry.demo.netapp.com/netapp/astra/acc/24.02.0-69"},
    {"op":"replace", "path":"/spec/astraVersion","value":"24.02.0-69"}
]'
sleep 60

echo
frames="/ | \\ -"
until [[ $(kubectl -n netapp-acc get astracontrolcenters.astra.netapp.io astra -o=jsonpath='{.status.conditions[?(@.type=="Upgrading")].reason}') == 'Complete' ]]; do
    for frame in $frames; do
       sleep 1; printf "\rwaiting for ACC upgrade to be complete $frame"
    done
done

echo
echo "############################"
echo "# upgrade to 24.02 finished on:"; date
echo "############################"

echo
echo "############################"
echo "# start trident upgrade"; date
echo "############################"


#trident 24.02 upgrade
if [ $(kubectl -n trident get tver -o=jsonpath='{.items[0].trident_version}') != "24.02.0" ]; then
    cd
    echo
    echo "############################################"
    echo "# download Trident package"
    echo "############################################"
    mv trident-installer trident-installer-old
    wget https://github.com/NetApp/trident/releases/download/v24.02.0/trident-installer-24.02.0.tar.gz -P ~/tarballs
    tar -xf ~/tarballs/trident-installer-24.02.0.tar.gz
    rm -f /usr/bin/tridentctl
    cp trident-installer/tridentctl /usr/bin/

    echo
    echo "###############################################"
    echo "# upload ACP image to the private registry"
    echo "###############################################"
    podman login -u registryuser -p Netapp1! registry.demo.netapp.com
    podman load --input ~/tarballs/trident-acp-24.02.0.tar
    podman tag trident-acp:24.02.0-linux-amd64 registry.demo.netapp.com/trident-acp:24.02.0
    podman push registry.demo.netapp.com/trident-acp:24.02.0

    echo
    echo "####################################################"
    echo "# launch the Trident upgrade on both RKE clusters"
    echo "####################################################"
    
    helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
    export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml
    helm upgrade trident netapp-trident/trident-operator --version 100.2402.0 --set acpImage=registry.demo.netapp.com/trident-acp:24.02.0 --set enableACP=true  --namespace trident
    export KUBECONFIG=/root/kubeconfigs/rke2/kube_config_cluster.yml
    helm upgrade trident netapp-trident/trident-operator --version 100.2402.0 --set acpImage=registry.demo.netapp.com/trident-acp:24.02.0 --set enableACP=true  --namespace trident

    echo
    echo "############################################"
    echo "# check Trident on RKE1"
    echo "############################################"
    export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml
    frames="/ | \\ -"
    until [ $(kubectl -n trident get tver -o=jsonpath='{.items[0].trident_version}') = "24.02.0" ]; do
      for frame in $frames; do
        sleep 1; printf "\rwaiting for the Trident upgrade to run $frame"
      done
    done
    echo
    while [ $(kubectl get -n trident pod | grep Running | grep -e '1/1' -e '2/2' -e '7/7' | wc -l) -ne 5 ]; do
      for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready $frame" 
      done
    done

    echo
    echo "############################################"
    echo "# check Trident on RKE2"
    echo "############################################"
    export KUBECONFIG=/root/kubeconfigs/rke2/kube_config_cluster.yml
    frames="/ | \\ -"
    until [ $(kubectl -n trident get tver -o=jsonpath='{.items[0].trident_version}') = "24.02.0" ]; do
      for frame in $frames; do
        sleep 1; printf "\rwaiting for the Trident upgrade to run $frame"
      done
    done
    echo
    while [ $(kubectl get -n trident pod | grep Running | grep -e '1/1' -e '2/2' -e '7/7' | wc -l) -ne 5 ]; do
      for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready $frame" 
      done
    done
fi

echo
echo "############################"
echo "# finished trident upgrade"; date
echo "############################"

echo
echo "############################"
echo "# start finetuning"; date
echo "############################"

echo
echo "########################################"
echo "# Configure iSCSI on the RKE2 nodes"
echo "########################################"
hosts=( "cp1.rke2" "cp2.rke2" "cp3.rke2" )
for host in "${hosts[@]}"
do
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i 's/^\(node.session.scan\).*/\1 = manual/' /etc/iscsi/iscsid.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i '2 a \    find_multipaths no' /etc/multipath.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i /iqn/s/.$/$i/ /etc/iscsi/initiatorname.iscsi"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart iscsid"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart multipathd"
  i=$((i+1))
done

export KUBECONFIG=/root/kubeconfigs/rke2/kube_config_cluster.yml
kubectl get -n trident po -l app=node.csi.trident.netapp.io -o name | xargs kubectl delete -n trident
sleep 5

frames="/ | \\ -"
while [ $(kubectl get -n trident pod | grep Running | grep -e '1/1' -e '2/2' -e '7/7' | wc -l) -ne 5 ]; do
    for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready $frame" 
    done
done

echo
echo "#######################################################################################################"
echo "CONFIGURE iSCSI on CLUSTER3 (SVM 'SVM2')"
echo "#######################################################################################################"

# Create the first iSCSI LIF on SVM2
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.247", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster3-01" }
    }
  },
  "name": "iSCSIlif1",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm2" }
}' "https://cluster3.demo.netapp.com/api/network/ip/interfaces"

# Create the second iSCSI LIF on SVM2
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.248", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster3-01" }
    }
  },
  "name": "iSCSIlif2",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm2" }
}' "https://cluster3.demo.netapp.com/api/network/ip/interfaces"

# Enable iSCSI on SVM2
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "enabled": true,
  "svm": { "name": "svm2" }
}' "https://cluster3.demo.netapp.com/api/protocols/san/iscsi/services"

echo
echo "########################################"
echo "# Configure iSCSI on the RKE1 nodes"
echo "########################################"

i=0
hosts=( "cp1.rke1" "cp2.rke1" "cp3.rke1" )
for host in "${hosts[@]}"
do
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i 's/^\(node.session.scan\).*/\1 = manual/' /etc/iscsi/iscsid.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i '2 a \    find_multipaths no' /etc/multipath.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i /iqn/s/.$/$i/ /etc/iscsi/initiatorname.iscsi"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart iscsid"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart multipathd"
  i=$((i+1))
done

export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml
kubectl get -n trident po -l app=node.csi.trident.netapp.io -o name | xargs kubectl delete -n trident
sleep 5

frames="/ | \\ -"
while [ $(kubectl get -n trident pod | grep Running | grep -e '1/1' -e '2/2' -e '7/7' | wc -l) -ne 5 ]; do
    for frame in $frames; do
        sleep 0.5; printf "\rWaiting for Trident to be ready $frame" 
    done
done

echo
echo "#######################################################################################################"
echo "CONFIGURE iSCSI on CLUSTER1 (SVM 'SVM1')"
echo "#######################################################################################################"

# Create the first iSCSI LIF on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.245", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster1-01" }
    }
  },
  "name": "iSCSIlif1",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/network/ip/interfaces"


# Create the second iSCSI LIF on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.246", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster1-02" }
    }
  },
  "name": "iSCSIlif2",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/network/ip/interfaces"

# Enable iSCSI on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "enabled": true,
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/protocols/san/iscsi/services"

echo
echo "#######################################################################################################"
echo "# labeling k8s in rke1 nodes for topology
echo "#######################################################################################################"

export KUBECONFIG=/root/kubeconfigs/rke1/kube_config_cluster.yml

kubectl label node cp1.rke1.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node cp2.rke1.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node cp3.rke1.demo.netapp.com "topology.kubernetes.io/region=east" --overwrite

kubectl label node cp1.rke1.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node cp2.rke1.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node cp3.rke1.demo.netapp.com "topology.kubernetes.io/zone=east1" --overwrite

echo
echo "#######################################################################################################"
echo "# labeling k8s in rke2 nodes for topology
echo "#######################################################################################################"

export KUBECONFIG=/root/kubeconfigs/rke2/kube_config_cluster.yml

kubectl label node cp1.rke2.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node cp2.rke2.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node cp3.rke2.demo.netapp.com "topology.kubernetes.io/region=east" --overwrite

kubectl label node cp1.rke2.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node cp2.rke2.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node cp3.rke2.demo.netapp.com "topology.kubernetes.io/zone=east1" --overwrite

echo
echo "#######################################################################################################"
echo "# ADD ALIAS TO BASHRC (need to reload bash after the completion of this script)"
echo "#######################################################################################################"

kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null
tridentctl completion bash > /etc/bash_completion.d/tridentctl

cp ~/.bashrc ~/.bashrc.bak
cat <<EOT >> ~/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k

alias kc='kubectl create'
alias kg='kubectl get'
alias kdel='kubectl delete'
alias kdesc='kubectl describe'
alias kedit='kubectl edit'
alias kx='kubectl exec'
alias trident='tridentctl -n trident'
EOT

echo
echo "############################"
echo "# finished script"; date
echo "############################"