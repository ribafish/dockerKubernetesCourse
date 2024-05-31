# Kubernetes starting steup notes

### Prerequisites

```
✗ minikube start

✗ minikube dashboard
```

### Build the docker image to put in a pod -> deployment

```
✗ docker build -t kub-first-app .
```

### Create the deployment

```
✗ kubectl create  deployment first-app --image=kub-first-app
```

Get deployments and pods

```
 ✗ kubectl get deployments.apps
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   0/1     1            0           10s

✗ kubectl get pods
NAME                         READY   STATUS             RESTARTS   AGE
first-app-6fc798dbcd-8qdz4   0/1     ImagePullBackOff   0          15s
```

The `first-app` deployment is not ready -> when `get pods` returns us `ImagePullBackOff`, it makes sense -> kubernetes is trying to pull the image from docker hub.

Delete the (faulty) deployment

```
✗ kubectl delete deployments.apps first-app
deployment.apps "first-app" deleted
```

Went to docker hub and created a repository to use for this: https://hub.docker.com/repository/docker/ribafish/tutorial-kube-first-app/

Then I re-tagged the old image to the repository name and pushed it to dockerhub:

```
✗ docker tag kub-first-app ribafish/tutorial-kube-first-app       
✗ docker push ribafish/tutorial-kube-first-app
```

Now create a deployment with the updated image and verify that it's ready:

```
✗ kubectl create deployment first-app --image=ribafish/tutorial-kube-first-app
deployment.apps/first-app created

✗ kubectl get deployments.apps
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   1/1     1            1           14s
```

### Expose the app in a deployment

To do that we need to create a service - instead of doing that manually we can use the `kubectl expose` command as such:

``` 
✗ kubectl expose deployments.apps first-app --port=8080 --type=LoadBalancer  
service/first-app exposed

✗ kubectl get services
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
first-app    LoadBalancer   10.98.76.77   <pending>     8080:30368/TCP   8s
kubernetes   ClusterIP      10.96.0.1     <none>        443/TCP          39m
```

We chose port 8080 as that's what the app is expecting in `app.js` and LoadBalancer as that will automatically manage the address for the service, as well as balance the load if we had more pods in the deployment. Note that LoadBalancer needs to be supported by the provider - minikube supports it. 

The `LoadBalancer` has external up as pending because we're using minikube, which doesn't have external ips since it's running locally - instead we can use the minikube command below to map it to a port we can use.

```
✗ minikube service first-app
|-----------|-----------|-------------|---------------------------|
| NAMESPACE |   NAME    | TARGET PORT |            URL            |
|-----------|-----------|-------------|---------------------------|
| default   | first-app |        8080 | http://192.168.49.2:30368 |
|-----------|-----------|-------------|---------------------------|
🏃  Starting tunnel for service first-app.
|-----------|-----------|-------------|------------------------|
| NAMESPACE |   NAME    | TARGET PORT |          URL           |
|-----------|-----------|-------------|------------------------|
| default   | first-app |             | http://127.0.0.1:53135 |
|-----------|-----------|-------------|------------------------|
```

Note: `minikube service` should open the webpage automatically in the browser.

### Crashing the pods

You can crash the pod by going to the url above (for this run it's `http://127.0.0.1:53135`) with `/error` appended. This will crash the app and the pod that started it (because that's how the `app.js` is written). However, if you go back to the original url without `/error`, that still works. That is because kubernetes restarted the pod when it crashed, which can be seen by:

```
✗ kubectl get pods
NAME                         READY   STATUS    RESTARTS      AGE
first-app-65cfd85cf7-m4thz   1/1     Running   1 (12s ago)   15m
```

We can see it was restarted. If we crash it again, the counter will increase. The restarts have a backoff strategy to prevent restart loops.

### Scaling in action

To autoscale we can use `kubectl scale`:

```
 ✗ kubectl scale deployments.apps first-app --replicas=3 
deployment.apps/first-app scaled

✗ kubectl get pods                                     
NAME                         READY   STATUS    RESTARTS        AGE
first-app-65cfd85cf7-c2vb2   1/1     Running   0               6s
first-app-65cfd85cf7-kh4sw   1/1     Running   0               6s
first-app-65cfd85cf7-m4thz   1/1     Running   2 (3m10s ago)   20m
```

We have the pod from before (2 restarts) and two new pods.

If we go to `/error` endpoint to crash one app and go back to the original one, we can see it's still running, even one (or more if you went to `/error` multiple times) pod is crashing:

```
✗ kubectl get pods
NAME                         READY   STATUS             RESTARTS      AGE
first-app-65cfd85cf7-c2vb2   0/1     CrashLoopBackOff   1 (16s ago)   2m1s
first-app-65cfd85cf7-kh4sw   1/1     Running            2 (17s ago)   2m1s
first-app-65cfd85cf7-m4thz   0/1     CrashLoopBackOff   2 (15s ago)   22m
```

To scale it back down simply set `--replicas=1`

```✗ kubectl scale deployments.apps first-app --replicas=1 
deployment.apps/first-app scaled

✗ kubectl get pods                                     
NAME                         READY   STATUS        RESTARTS        AGE
first-app-65cfd85cf7-c2vb2   1/1     Terminating   2 (2m10s ago)   3m55s
first-app-65cfd85cf7-kh4sw   1/1     Terminating   2 (2m11s ago)   3m55s
first-app-65cfd85cf7-m4thz   1/1     Running       3 (2m9s ago)    23m

✗ kubectl get pods
NAME                         READY   STATUS    RESTARTS       AGE
first-app-65cfd85cf7-m4thz   1/1     Running   3 (3m5s ago)   24m
```

### Updating deployments

To update the deployment after doing some changes in code (for example, adding line 8 in `app.js`), you need to do:

1. Rebuild and push a new image to dockerhub:

```
✗ docker build . -t ribafish/tutorial-kube-first-app

✗ docker push ribafish/tutorial-kube-first-app
```

2. Set a new image to a container:

```
✗ kubectl set image deployments.apps/first-app tutorial-kube-first-app=ribafish/tutorial-kube-first-app
```

The syntax is to define which deployment (ex. `deployments.apps/first-app `) and then which container should be updated with which image with syntax `<container>=<newImage>` (ex. `tutorial-kube-first-app=ribafish/tutorial-kube-first-app`). However, just doing this we can see when we get deployments that it didn't restart, as when we go to the endpoint, there's no change. That's because by default kubernetes doesn't pull an image unless it has a different tag (or we force it to).

To overcome that, we need to version our image and then set it to the deployment:


```
✗ docker build . -t ribafish/tutorial-kube-first-app:2

✗ docker push ribafish/tutorial-kube-first-app:2

✗ kubectl set image deployments.apps/first-app tutorial-kube-first-app=ribafish/tutorial-kube-first-app:2
deployment.apps/first-app image updated

✗ kubectl rollout status deployment.apps/first-app
deployment "first-app" successfully rolled out
```

### Deployment rollbacks 

If we make the update fail (here we're referencing an image tag that doens't exist):

```
✗ kubectl set image deployments.apps/first-app tutorial-kube-first-app=ribafish/tutorial-kube-first-app:3
deployment.apps/first-app image updated

✗ kubectl rollout status deployment.apps/first-app                                                       
Waiting for deployment "first-app" rollout to finish: 1 old replicas are pending termination...

^C

✗ kubectl get pods
NAME                         READY   STATUS             RESTARTS   AGE
first-app-7d8f6cbf65-wjwwb   1/1     Running            0          4m57s
first-app-84db5c5d78-ncjtj   0/1     ImagePullBackOff   0          87s
```

When can see that the rollout is waiting for the old pod to termninate, however that won't terminate until the new one is up and running. The new one is having errors with pulling an image. We can also see that in the `minikube dashboard` when looking at the pods.

To roll back a deployment:

```
✗ kubectl rollout undo deployment.apps/first-app
deployment.apps/first-app rolled back

✗ kubectl get pods                              
NAME                         READY   STATUS    RESTARTS   AGE
first-app-7d8f6cbf65-wjwwb   1/1     Running   0          6m38s

✗ kubectl rollout status deployment.apps/first-app
deployment "first-app" successfully rolled out
```

### Deployment rollout history

We can see the rollout history with

```
✗ kubectl rollout history deployment.apps/first-app
deployment.apps/first-app 
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
```

And to get more details about a specific rollout

```
✗ kubectl rollout history deployment.apps/first-app --revision=3 
deployment.apps/first-app with revision #3
Pod Template:
  Labels:	app=first-app
	pod-template-hash=84db5c5d78
  Containers:
   tutorial-kube-first-app:
    Image:	ribafish/tutorial-kube-first-app:3
    Port:	<none>
    Host Port:	<none>
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>

✗ kubectl rollout history deployment.apps/first-app --revision=1
deployment.apps/first-app with revision #1
Pod Template:
  Labels:	app=first-app
	pod-template-hash=65cfd85cf7
  Containers:
   tutorial-kube-first-app:
    Image:	ribafish/tutorial-kube-first-app
    Port:	<none>
    Host Port:	<none>
    Environment:	<none>
    Mounts:	<none>

✗ kubectl rollout history deployment.apps/first-app --revision=4
deployment.apps/first-app with revision #4
Pod Template:
  Labels:	app=first-app
	pod-template-hash=7d8f6cbf65
  Containers:
   tutorial-kube-first-app:
    Image:	ribafish/tutorial-kube-first-app:2
    Port:	<none>
    Host Port:	<none>
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
```

From this we can see the revision 3 is the one that had the wrong tag, and revision 1 is the original rollout that used the `latest` tag. Revision 4 is the one that reverted back to 2, so that's why revision 2 is missing.

If we wanted to roll back to a specific revision, for example the original one we can do:

```
✗ kubectl rollout undo deployment.apps/first-app --to_revision=1 
deployment.apps/first-app rolled back
```

### Cleanup

```
 ✗ kubectl delete services first-app
service "first-app" deleted

✗ kubectl delete deployments.apps first-app
deployment.apps "first-app" deleted
```
