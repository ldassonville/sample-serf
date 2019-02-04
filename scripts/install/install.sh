#!/bin/bash

source config-local.cfg


function bootstrap(){

    # Create openshift project
    oc new-project ${OC_NAMESPACE}

    oc project $OC_NAMESPACE

    # Create service account
    oc create sa ${OC_SERVICE_ACCOUNT_NAME}

    oc policy add-role-to-user edit system:serviceaccount:$TILLER_NAMESPACE:${OC_SERVICE_ACCOUNT_NAME}

    # Get service account key
    oc sa get-token ${OC_SERVICE_ACCOUNT_NAME}


    export TILLER_NAMESPACE=$OC_NAMESPACE
    oc policy add-role-to-user edit system:serviceaccount:$TILLER_NAMESPACE:$OC_SERVICE_ACCOUNT_NAME
    helm init --service-account=$OC_SERVICE_ACCOUNT_NAME
}


function deploy_img(){

    img_name=sample-serf
    img_tag=latest

    img_local=${img_name}:${img_tag}
    img_remote=${OC_REGISTRY}/${OC_NAMESPACE}/  ${img_name}:${img_tag}

    docker tag ${img_local} ${img_remote}
    docker login -p `oc whoami -t` -u unused ${OC_REGISTRY}
    docker push ${img_remote}


}

function login_sa(){
	oc login --insecure-skip-tls-verify "$OC_URL" --token="$OC_SERVICE_ACCOUNT_TOKEN"
	oc project $OC_NAMESPACE
}


function init_helm(){
	export TILLER_NAMESPACE=${OC_NAMESPACE}

	helm init --client-only --service-account $OC_SERVICE_ACCOUNT_NAME
}

function install_release(){


    cd ../../deployments/helm/sample-serf
	CHART_PATH=`pwd`

	echo ${CHART_PATH}
	DEPLOYS=$(helm ls | grep $APP_RELEASE_NAME | wc -l)
    echo "Deploy : '${DEPLOYS}'"

	if [[ ${DEPLOYS} -eq 0 ]]; then
		echo "helm install --name=${APP_RELEASE_NAME} ${CHART_PATH}"
		helm install --name=${APP_RELEASE_NAME} ${CHART_PATH};
	else
		echo "helm upgrade ${APP_RELEASE_NAME} ${CHART_PATH}; "
		helm upgrade ${APP_RELEASE_NAME} ${CHART_PATH};
	fi

}

deploy_img

login_sa

init_helm

install_release

