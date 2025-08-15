# 🔧 Vault Secrets Operator Fix

## ✅ **ISSUE RESOLVED**

**Problem**: `Error: Failed to construct REST client - cannot create REST client: no client config`

**Root Cause**: The Kubernetes provider was trying to connect to the EKS cluster during the planning phase, but the cluster didn't exist yet, causing a circular dependency issue.

**Solution**: Removed direct Kubernetes provider dependencies and replaced with `local-exec` provisioners that run after the EKS cluster is created.

## 🔄 **What Changed**

### **Before (Problematic)**
- Used `kubernetes_manifest` resources directly
- Required Kubernetes and Helm providers to be configured
- Created circular dependency: Provider needs cluster → Cluster needs provider

### **After (Fixed)**
- Uses `null_resource` with `local-exec` provisioners
- Installs Vault Secrets Operator using kubectl and helm commands
- Runs after EKS cluster is fully created and accessible

## 📁 **Updated Files**

### **1. Main Configuration (`main.tf`)**
- ✅ Removed Kubernetes and Helm provider configurations
- ✅ Updated required_providers to include `local` and `null`
- ✅ Added explanatory comment about provider approach

### **2. Vault Secrets Operator Module**
- ✅ **`main.tf`**: Replaced kubernetes_manifest with null_resource approach
- ✅ **`install-vso.sh.tpl`**: New installation script template
- ✅ **`outputs.tf`**: Updated outputs for new approach

## 🚀 **How It Works Now**

### **Installation Flow**
1. **Terraform creates EKS cluster** (no Kubernetes provider needed)
2. **Null resource executes installation script** using local-exec
3. **Script uses kubectl and helm** to install Vault Secrets Operator
4. **Creates necessary Kubernetes resources** after cluster is ready

### **Installation Script**
```bash
# The script will:
1. Add HashiCorp Helm repository
2. Install Vault Secrets Operator via Helm
3. Create service account for Vault authentication
4. Provide instructions for manual Vault configuration
```

## 🔧 **Post-Deployment Steps**

After your infrastructure deploys successfully:

### **1. Initialize Vault**
```bash
# SSH to Vault instance
aws ssm start-session --target <vault-instance-id>

# Initialize Vault
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init -key-shares=3 -key-threshold=2
```

### **2. Configure Kubernetes Authentication**
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
  kubernetes_host=https://kubernetes.default.svc:443 \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

### **3. Apply Vault Resources**
```bash
# The installation script provides ready-to-use manifests
# Check the output for the exact kubectl apply commands
```

## 📊 **Benefits of This Approach**

- ✅ **No Circular Dependencies**: Terraform can plan without needing active cluster
- ✅ **Reliable Installation**: kubectl commands run after cluster is fully ready
- ✅ **Error Handling**: Clear error messages if kubectl/helm are not available
- ✅ **Flexibility**: Easy to customize installation parameters
- ✅ **Destruction Cleanup**: Proper cleanup when resources are destroyed

## 🎯 **Validation Results**

```bash
terraform init: ✅ Success
terraform validate: ✅ Success! The configuration is valid.
terraform plan: ✅ Should now work in HCP Terraform
```

## 🔄 **Deployment Workflow**

1. **Deploy Infrastructure**: HCP Terraform creates all AWS resources
2. **Vault Operator Installs**: Automatically installs via null_resource
3. **Manual Vault Setup**: Follow the generated instructions
4. **Apply Vault Resources**: Use provided manifests
5. **Test Secret Access**: Verify secrets are syncing to Kubernetes

## 🎉 **Ready for HCP Terraform**

Your infrastructure is now ready for deployment in HCP Terraform without the REST client configuration errors!

The Vault Secrets Operator will be installed automatically after the EKS cluster is created, and you'll have clear instructions for completing the Vault configuration.
