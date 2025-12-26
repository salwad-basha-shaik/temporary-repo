#!/bin/bash
set -euo pipefail

############################################
# CONFIG
############################################
NAMESPACE="argocd"
BACKUP_ROOT="/opt/argocd-backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="${BACKUP_ROOT}/argocd-backup-${DATE}"

############################################
# PRE-CHECKS
############################################
command -v kubectl >/dev/null || {
  echo "kubectl not found"
  exit 1
}

mkdir -p "${BACKUP_DIR}"

echo "📦 Starting ArgoCD backup: ${BACKUP_DIR}"

############################################
# CORE NAMESPACE OBJECTS
############################################
echo "🔹 Backing up namespace resources"
kubectl get all -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/all.yaml

############################################
# CONFIGMAPS
############################################
echo "🔹 Backing up ConfigMaps"
kubectl get configmaps -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/configmaps.yaml

############################################
# SECRETS (CRITICAL)
############################################
echo "🔹 Backing up Secrets"
kubectl get secrets -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/secrets.yaml

############################################
# APPLICATIONS & PROJECTS (CRDs)
############################################
echo "🔹 Backing up ArgoCD Applications & Projects"
kubectl get applications.argoproj.io -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/applications.yaml
kubectl get appprojects.argoproj.io -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/appprojects.yaml

############################################
# RBAC
############################################
echo "🔹 Backing up RBAC"
kubectl get roles,rolebindings -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/rbac.yaml
kubectl get serviceaccounts -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/serviceaccounts.yaml

############################################
# INGRESS (IF ANY)
############################################
echo "🔹 Backing up Ingress"
kubectl get ingress -n ${NAMESPACE} -o yaml > ${BACKUP_DIR}/ingress.yaml || true

############################################
# CRDs (CLUSTER LEVEL)
############################################
echo "🔹 Backing up CRDs"
kubectl get crd applications.argoproj.io -o yaml > ${BACKUP_DIR}/crd-applications.yaml
kubectl get crd appprojects.argoproj.io -o yaml > ${BACKUP_DIR}/crd-appprojects.yaml

############################################
# INSTALL MANIFEST
############################################
echo "🔹 Saving ArgoCD install manifest"
curl -fsSL \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  -o ${BACKUP_DIR}/argocd-install.yaml

############################################
# IMAGE VERSIONS (FOR FORENSICS)
############################################
echo "🔹 Saving image versions"
kubectl get deployments -n ${NAMESPACE} \
  -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{.spec.template.spec.containers[*].image}{"\n"}{end}' \
  > ${BACKUP_DIR}/images.txt

############################################
# METADATA
############################################
cat <<EOF > ${BACKUP_DIR}/metadata.txt
Backup Date: ${DATE}
Cluster: $(kubectl config current-context)
Namespace: ${NAMESPACE}
EOF

############################################
# TAR & OPTIONAL COMPRESSION
############################################
echo "📦 Compressing backup"
tar -czf ${BACKUP_DIR}.tar.gz -C ${BACKUP_ROOT} $(basename ${BACKUP_DIR})
rm -rf ${BACKUP_DIR}

echo "✅ ArgoCD backup completed:"
echo "➡ ${BACKUP_DIR}.tar.gz"
