# CI/CD Pipeline Assignment
### Git + Jenkins + Kubernetes on AWS EC2

**Submitted by:** Rohan Deb  
**Repository:** [FinacPlus-assignment](https://github.com/rohandeb2/FinacPlus-assignment)  
**Date:** April 2026

---

## What This Project Does

This project sets up a complete CI/CD pipeline that automatically builds and deploys an application whenever code is pushed to GitHub.

The flow is:
1. Developer pushes code to GitHub
2. GitHub sends a webhook to Jenkins
3. Jienkins builds a Docker image
4. Jenkins runs tests inside the container
5. Jenkins pushes the image to Docker Hub
6. Jenkins deploys the new image to Kubernetes
7. Kubernetes does a rolling update with zero downtime

---

## Architecture Diagram

<!-- PASTE YOUR ARCHITECTURE DIAGRAM IMAGE HERE -->
<!-- To add image: drag and drop the image file directly into this file on GitHub while editing -->

```
Developer
    |
    | git push
    v
GitHub Repository
    |
    | webhook (HTTP POST)
    v
Jenkins (port 8080 on EC2)
    |
    |-- Stage 1: Checkout code
    |-- Stage 2: Build Docker image
    |-- Stage 3: Run tests (npm test)
    |-- Stage 4: Push to Docker Hub (rohan700/cicd-demo)
    |-- Stage 5: Deploy to Kubernetes
    v
Kubernetes (Minikube on EC2)
    namespace: production
    2 pods running, rolling update, zero downtime
```

---

## Tools Used

| Tool | Purpose |
|------|---------|
| AWS EC2 (t2.medium, Ubuntu 22.04) | Server to run everything |
| Jenkins LTS | CI/CD automation server |
| Docker | Build and package the application |
| Minikube | Local Kubernetes cluster |
| kubectl | Deploy to Kubernetes |
| GitHub | Source code hosting + webhooks |
| Docker Hub | Store built Docker images |
| Node.js 20 (Alpine) | Sample application |

---

## Project Structure

```
FinacPlus-assignment/
├── Jenkinsfile            <- Full 5-stage pipeline in Groovy
├── Dockerfile             <- How to build the Docker image
├── package.json           <- Node.js app dependencies
├── src/
│   └── index.js           <- Simple Node.js web app
└── k8s/
    └── deployment.yaml    <- Kubernetes Deployment + Service
```

---

## How to Set Up and Run

### Prerequisites on EC2

```bash
# Java (for Jenkins)
sudo apt-get install -y fontconfig openjdk-17-jre

# Jenkins
sudo apt-get install -y jenkins
sudo systemctl start jenkins

# Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart jenkins

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Start Kubernetes

```bash
minikube start --driver=docker --memory=2200 --cpus=2
kubectl create namespace production
kubectl apply -f k8s/deployment.yaml
```

### Jenkins Setup

1. Open `http://YOUR_EC2_IP:8080`
2. Install plugins: Docker Pipeline, Kubernetes CLI, Git, Pipeline, GitHub Integration
3. Add credentials:
   - ID `docker-hub-credentials` — Docker Hub username + password
   - ID `kubeconfig-credentials` — upload `/home/ubuntu/.kube/config`
4. Create Pipeline job → SCM → Git → this repo → `Jenkinsfile`

### Fix kubeconfig permissions for Jenkins

```bash
sudo cp /home/ubuntu/.kube/config /var/lib/jenkins/kubeconfig
sudo chown jenkins:jenkins /var/lib/jenkins/kubeconfig
sudo chmod 644 /home/ubuntu/.minikube/profiles/minikube/client.crt
sudo chmod 644 /home/ubuntu/.minikube/profiles/minikube/client.key
sudo chmod 644 /home/ubuntu/.minikube/ca.crt
sudo usermod -aG ubuntu jenkins
sudo systemctl restart jenkins
```

---

## Pipeline Stages Explained

| Stage | What it does |
|-------|-------------|
| Checkout | Clones latest code from `main` branch |
| Build Docker Image | `docker build` — tags as `rohan700/cicd-demo:BUILD_NUMBER` |
| Run Tests | `npm test` runs inside the built container |
| Push to Docker Hub | Pushes versioned tag + `latest` to Docker Hub |
| Deploy to Kubernetes | `kubectl set image` + waits for `rollout status` to confirm |

---

## Evidence

### 1. Jenkins Pipeline — All Stages Green

<!-- PASTE SCREENSHOT HERE -->
<!-- Go to Jenkins → cicd-demo-pipeline → last build → you will see 5 green stages -->

---

### 2. Jenkins Console Output — Build Successful

<!-- PASTE SCREENSHOT HERE -->
<!-- Jenkins → last build → Console Output → scroll to bottom → shows "BUILD SUCCESSFUL" -->

---

### 3. Rollout Successfully Completed

Terminal output after deployment:

```
$ kubectl rollout status deployment/cicd-demo-deployment -n production

Waiting for deployment "cicd-demo-deployment" to finish...
deployment "cicd-demo-deployment" successfully rolled out
```

<!-- PASTE SCREENSHOT HERE -->

---

### 4. Pods Running in Kubernetes

```
$ kubectl get pods -n production -o wide

NAME                                  READY   STATUS    RESTARTS   AGE
cicd-demo-deployment-xxxxx-yyyyy      1/1     Running   0          2m
cicd-demo-deployment-xxxxx-zzzzz      1/1     Running   0          2m
```

<!-- PASTE SCREENSHOT HERE -->

---

### 5. Application Responding

```
$ curl http://$(minikube ip):30080

Hello from CI/CD Pipeline! Build working.
```

<!-- PASTE SCREENSHOT HERE -->

---

### 6. GitHub Webhook — Delivery Successful (Green Tick)

<!-- PASTE SCREENSHOT HERE -->
<!-- GitHub → repo → Settings → Webhooks → click webhook → Recent Deliveries → green tick + HTTP 200 -->

---

## Security Practices

- Docker Hub credentials stored in Jenkins Credentials store — never in code
- Container runs as non-root user (`appuser`) inside Docker
- Kubernetes resource limits set on containers
- `docker logout` runs after every push
- kubeconfig stored at `/var/lib/jenkins/kubeconfig` with `jenkins:jenkins` ownership
- Image tagged with Jenkins build number for full traceability

---

## Challenges and Fixes

**Problem:** Jenkins couldn't run `docker` commands  
**Fix:** Added jenkins user to docker group and restarted Jenkins
```bash
sudo usermod -aG docker jenkins && sudo systemctl restart jenkins
```

**Problem:** `kubectl` failed — couldn't read Minikube certificates  
**Fix:** Copied kubeconfig to Jenkins home directory and fixed file permissions
```bash
sudo cp /home/ubuntu/.kube/config /var/lib/jenkins/kubeconfig
sudo chown jenkins:jenkins /var/lib/jenkins/kubeconfig
```

**Problem:** GitHub webhook returning error, pipeline not auto-triggering  
**Fix:** Opened port 8080 in EC2 Security Group inbound rules for `0.0.0.0/0`

---

## Useful Commands

```bash
# Watch pods live
kubectl get pods -n production -w

# Check deployment details
kubectl describe deployment cicd-demo-deployment -n production

# View rollout history
kubectl rollout history deployment/cicd-demo-deployment -n production

# Roll back to previous version
kubectl rollout undo deployment/cicd-demo-deployment -n production

# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check Minikube status
minikube status
```

---

*Submitted as part of the DevOps Engineer hiring assignment.*
