Plan
===

Need to setup JIRA app on AWS.

- [x] cloud native
- [x] high available
- [x] cheap
- [x] secured

## Cloud Native

### 1. Run app locally

**Problem**

We don`t know how this app works, what db required.
How app is configured?

**Plan**

ETA: **2 working days**

- [x] 1. Request access to the repository.
- [x] 2. Investigate the app.
- [x] 3. Extend this plan after investigation.
- [x] 4. Run app locally.

**Acceptance criterias**

- [x] 1. App works locally with docker-compose.
- [x] 2. We understand all applications dependencies and configuration.

### 2. Deploy in AWS

**Problem**

We have to understand what services to use in order to get a working infrastructure.
We want to have it in a cloud.

**Plan**

ETA: **5 working days**

- [x] 1. Create VPC.
- [x] 2. Create RDS postgreSQL.
- [x] 3. Create ECS task for API.
- [x] 4. Create ECS task for WEB.
- [x] 5. Create ALB.

**Acceptance criterias**

- [x] 1. Infrastructure IaC with terraform.
- [x] 2. App works via public IP.

### 3. Deploy an application on a Kubernetes

**Problem**

We need to understand how Kubernetes works with AWS.
We need to install and use eksctl and kubectl.

**Plan**

ETA: **3 working days**

- [x] 1. Create k8s cluster in AWS.
- [x] 2. Сreate the manifest files (Deployment, Service, Ingress-nginx) we need.
- [x] 3. Create ClusterIssuer to obtain a Let's Encrypt Certificate.

**Acceptance criterias**

- [x] 1. App works via DNS.
- [x] 2. Cert-manager for HTTPS.