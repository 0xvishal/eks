# Configure EKS with ALB, Inress, Autoscaler, LoadbalancerController using Terraform


## Node Affinity
Node Affinity in Kubernetes is a feature that allows you to control which nodes your pods can be scheduled on, based on labels assigned to the nodes. It's part of the broader concept of affinity and anti-affinity, which helps in defining rules for pod placement in a Kubernetes cluster.

### How Node Affinity Works: 
- **Node Labels**: Nodes in a Kubernetes cluster can have labels, which are key-value pairs that can be used to identify and categorize them (e.g., `env=production`, `type=gpu`).
- **Node Affinity Rules**: You can define affinity rules in a pod's specification to express preferences (soft) or requirements (hard) for scheduling the pod on nodes with specific labels.

### Types of Node Affinity:
1. **RequiredDuringSchedulingIgnoredDuringExecution**: 
   - This is a hard rule. The pod will only be scheduled on nodes that match the specified node affinity rules. If no nodes match, the pod won't be scheduled.
   - Example: If you specify that a pod should be scheduled on a node with the label `env=production`, the scheduler will only place the pod on nodes that have this label.

2. **PreferredDuringSchedulingIgnoredDuringExecution**:
   - This is a soft rule. The scheduler will try to place the pod on a node that matches the affinity rules, but if none are available, it will still schedule the pod on other nodes.
   - Example: If you prefer to run a pod on nodes with the label `type=gpu`, the scheduler will prioritize those nodes, but it will fall back to other nodes if necessary.

### Use Cases:
- **Workload Isolation**: Running different environments (e.g., development, staging, production) on different sets of nodes.
- **Optimized Resource Utilization**: Scheduling pods that require specific hardware (like GPUs) on appropriate nodes.
- **Compliance and Security**: Ensuring that sensitive workloads run only on specific nodes that meet security or compliance requirements.

### Example YAML Configuration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: env
            operator: In
            values:
            - production
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: type
            operator: In
            values:
            - gpu
  containers:
  - name: my-container
    image: my-image
```

In this example, the pod will only be scheduled on nodes labeled with `env=production`, and it will prefer nodes labeled with `type=gpu` if available.

### Ignored During Execution:
Both types of node affinity rules use "IgnoredDuringExecution," which means the rules are only considered during the initial scheduling. They won't be enforced if node labels change after the pod has been scheduled.

Node Affinity is a powerful tool in Kubernetes for controlling pod placement, allowing for fine-grained control over how and where workloads are deployed in a cluster.


## Taints and Tolerations
**Taints and Tolerations** in Kubernetes are mechanisms that allow you to control how pods are scheduled onto nodes. They work together to prevent certain pods from being scheduled on certain nodes, unless the pods explicitly tolerate the taint.

### Taints
- **Definition**: A taint is a key-value pair applied to a node that affects which pods can be scheduled on that node. Taints are used to mark nodes as being "unsuitable" for certain types of workloads.
- **Purpose**: By applying a taint to a node, you can prevent any pod that does not tolerate the taint from being scheduled on that node.
  
Each taint has three components:
1. **Key**: A string that identifies the taint.
2. **Value**: An optional string that provides additional information about the taint.
3. **Effect**: Specifies what will happen to a pod that doesn't tolerate the taint. There are three effects:
   - `NoSchedule`: The pod won't be scheduled on the node.
   - `PreferNoSchedule`: Kubernetes will try to avoid scheduling the pod on the node, but it may still do so if necessary.
   - `NoExecute`: Existing pods on the node that don't tolerate the taint will be evicted.

### Example of a Taint:
```bash
kubectl taint nodes node1 key=value:NoSchedule
```
This command applies a taint with key `key`, value `value`, and effect `NoSchedule` to `node1`. Pods that do not tolerate this taint will not be scheduled on `node1`.

### Tolerations
- **Definition**: A toleration is a key-value pair that is applied to a pod to allow it to be scheduled on nodes with matching taints.
- **Purpose**: Tolerations are used in a pod's specification to indicate that the pod can tolerate a specific taint on a node. This allows the pod to be scheduled on nodes that would otherwise reject it.

### Example of a Toleration in a Pod Spec:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
  - name: my-container
    image: my-image
```
This pod has a toleration that matches the taint `key=value:NoSchedule`. As a result, it can be scheduled on nodes that have this taint.

### Key Points:
1. **Node Behavior**: A node with a taint will repel all pods except those that have a matching toleration.
2. **Pod Behavior**: A pod with a toleration can be scheduled on nodes with matching taints.
3. **Taints and Tolerations Together**: They provide a way to control pod placement in the cluster. Nodes can be marked (tainted) to only allow certain pods to run on them, and pods can be marked (tolerated) to indicate that they are allowed to run on those nodes.

### Use Cases:
- **Dedicated Nodes**: You can taint nodes to dedicate them to certain workloads (e.g., only allow pods that are tolerant of a specific taint, such as `dedicated=production`).
- **Avoiding Resource Conflicts**: Prevent certain pods from being scheduled on nodes that are reserved for specific tasks (e.g., nodes with specialized hardware like GPUs).
- **Node Maintenance**: Taint nodes to evict pods and prevent new ones from being scheduled during maintenance.

### Example Scenario:
1. **Taint Application**:
   ```bash
   kubectl taint nodes node1 dedicated=production:NoSchedule
   ```
   - This taints `node1` to repel any pods that do not have a matching toleration for `dedicated=production`.

2. **Toleration in Pod Spec**:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: production-pod
   spec:
     tolerations:
     - key: "dedicated"
       operator: "Equal"
       value: "production"
       effect: "NoSchedule"
     containers:
     - name: my-container
       image: my-image
   ```
   - This pod can now be scheduled on `node1` because it tolerates the `dedicated=production:NoSchedule` taint.

By using taints and tolerations, Kubernetes administrators can exert fine-grained control over how workloads are distributed across nodes, ensuring that pods run in the most appropriate environments within a cluster.


## why Ingress does not expose arbitrary ports or protocols?
Kubernetes Ingress does not expose arbitrary ports or protocols because it is specifically designed to handle HTTP and HTTPS traffic at the application layer (Layer 7 of the OSI model). Ingress is focused on managing and routing HTTP/HTTPS requests to services within a Kubernetes cluster, providing features like host-based or path-based routing, SSL termination, and more. Here's why it doesn't handle arbitrary ports or protocols:

### 1. **Layer 7 Focus (HTTP/HTTPS)**:
   - **Ingress Purpose**: Ingress is a Layer 7 load balancer, meaning it's intended to manage traffic based on HTTP/HTTPS headers, URLs, and methods. It's specifically designed to interpret and route traffic based on these protocols.
   - **Protocol-Specific Features**: Ingress supports features specific to HTTP/HTTPS, like SSL termination, host/path-based routing, and rewrites. These features wouldn't be applicable or useful for arbitrary protocols, which might not have the same header structure or require the same kind of routing logic.

### 2. **Port and Protocol Limitations**:
   - **Fixed Port (80/443)**: Ingress controllers typically listen on standard HTTP (port 80) and HTTPS (port 443) ports. This limitation aligns with the goal of managing web traffic, where these ports are standard.
   - **Arbitrary Ports**: Exposing arbitrary ports (like 8080, 5000, etc.) or protocols (like TCP, UDP) would require the Ingress to support a much wider range of networking behaviors, which goes beyond its intended purpose.

### 3. **Alternative Solutions for Other Protocols**:
   - **Services and LoadBalancers**: For non-HTTP/HTTPS traffic, Kubernetes provides other resources like `Service` with type `NodePort` or `LoadBalancer`, which can expose arbitrary ports and protocols, including TCP and UDP.
   - **Network Policies**: Kubernetes network policies and services can be used to manage and control traffic for non-HTTP protocols, ensuring that Ingress remains focused on HTTP/HTTPS while other mechanisms handle different types of traffic.

### 4. **Simplified Configuration and Security**:
   - **Security and Complexity**: Restricting Ingress to HTTP/HTTPS reduces the complexity of managing diverse protocols and ports, which can introduce security risks. By focusing on Layer 7 traffic, Ingress can implement more targeted security measures, such as SSL/TLS management.
   - **Easier Management**: Keeping Ingress focused on HTTP/HTTPS allows administrators to manage and configure it more easily without worrying about the complexities of handling multiple protocols and arbitrary ports.

### 5. **Extension through Custom Resources**:
   - **Ingress Custom Resources**: For more advanced use cases, including routing different protocols, Kubernetes allows the use of custom resources and CRDs (Custom Resource Definitions) like `Gateway` in the Gateway API, which is designed to extend beyond HTTP/HTTPS routing and provide more flexible, protocol-agnostic traffic management.

### Summary
Ingress is purpose-built for HTTP/HTTPS traffic management, leveraging the specific needs and behaviors of these protocols. For other ports and protocols, Kubernetes offers different tools (like Services, LoadBalancers, and custom resources) that are better suited to handle those use cases. This separation of concerns helps to keep the Kubernetes networking stack more organized, secure, and maintainable.


## Init containers
**Init containers** in Kubernetes are specialized containers that run before the main application containers in a pod. They are designed to perform setup or initialization tasks that need to be completed before the main application starts. Init containers offer a powerful way to ensure that the pod’s environment is ready and configured correctly for the main containers.

### Key Features of Init Containers:

1. **Run Sequentially**: Init containers run one after the other in a specific order, and each must complete successfully before the next one starts. Only after all init containers have finished will the main application containers start.

2. **Separate from Main Containers**: Init containers are defined separately from the main application containers within the pod specification. They have their own specifications, including images, commands, and volumes, and can use different images than the main containers.

3. **Failing an Init Container**: If any init container fails, Kubernetes will restart the pod, retrying the init containers until they all succeed. This ensures that the pod's main containers only start when the required conditions are met.

### Common Use Cases for Init Containers:

1. **Setup Tasks**:
   - **Configuration Management**: Init containers can be used to fetch or generate configuration files or environment variables that the main containers require.
   - **Data Preparation**: They can prepare data by downloading or extracting files that the main application needs to operate.

2. **Dependency Management**:
   - **Service Dependency**: If the main application container requires another service to be up and running (e.g., a database), an init container can check for this dependency and delay the startup of the main container until the service is available.
   - **Database Migrations**: An init container can be used to run database migrations before the main application starts.

3. **Security and Compliance**:
   - **Certificate Installation**: Init containers can download and install security certificates or keys needed by the main application.
   - **System Checks**: They can run security or compliance checks on the node before the main application container runs.

4. **Environment Validation**:
   - **Network Configuration**: Init containers can validate network configurations, such as ensuring that necessary ports are open or specific network routes are available.
   - **Pre-checks**: They can perform health checks or verify prerequisites, such as available storage or memory.

### Example of Using Init Containers:

Here’s an example of a pod with an init container that waits for a service to become available before starting the main application container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  initContainers:
  - name: wait-for-service
    image: busybox
    command: ['sh', '-c', 'until nslookup my-service; do echo waiting for my-service; sleep 2; done']
  containers:
  - name: my-app
    image: my-app-image
    ports:
    - containerPort: 80
```

### Explanation:
- **Init Container (`wait-for-service`)**: This init container uses the `busybox` image to run a simple shell script that waits until the `my-service` DNS entry is resolvable (indicating the service is available). It retries every 2 seconds until it succeeds.
- **Main Container (`my-app`)**: Once the init container has successfully completed, the main application container (`my-app`) will start.

### Benefits of Init Containers:
- **Modularity**: Init containers allow you to break down initialization tasks into distinct, manageable units. This modularity makes it easier to maintain and update the setup process.
- **Isolation**: Init containers run in isolation from the main application, allowing you to use different images, tools, and configurations without affecting the main container's environment.
- **Retry Logic**: Kubernetes automatically handles the retry logic for init containers, ensuring that the initialization tasks are completed before the application starts.

### Summary:
Init containers in Kubernetes are essential tools for preparing the environment before the main application containers run. They provide a robust way to handle setup tasks, manage dependencies, and ensure that all necessary conditions are met before the main application starts. This enhances the reliability and consistency of applications deployed in Kubernetes.


## Pod Disruption Budget
A **Pod Disruption Budget (PDB)** in Kubernetes is a mechanism that helps you maintain a certain level of availability for your application during voluntary disruptions, such as node upgrades, scaling events, or pod evictions. PDBs ensure that a minimum number of pods (or a percentage of the total) remain available during these disruptions, preventing the application from going completely offline.

### Key Concepts of Pod Disruption Budgets:

1. **Voluntary Disruptions**:
   - These are disruptions initiated by Kubernetes or an administrator, such as:
     - Draining a node (e.g., for maintenance or scaling down).
     - Manual deletion of pods.
     - Cluster upgrades.
     - Changes in cluster configuration that trigger pod rescheduling.
   - PDBs are specifically designed to manage these types of disruptions.

2. **Minimum Available Pods**:
   - A PDB specifies the minimum number of pods that must be running and available at any given time. This can be expressed as an absolute number or as a percentage of the total number of pods in the deployment.
   - Kubernetes will not allow more than the permitted number of disruptions (based on the PDB) to ensure that the application remains sufficiently available.

3. **Maximum Unavailable Pods**:
   - Alternatively, a PDB can specify the maximum number of pods that can be unavailable at any given time. This is another way to define the budget for disruptions.

### How Pod Disruption Budgets Work:

- **PDB Specification**: You create a PDB by defining it in a YAML manifest. You specify the minimum number of available pods or the maximum number of unavailable pods, and associate the PDB with one or more pod labels that identify the pods it applies to.

- **Controller Behavior**: When a voluntary disruption occurs, Kubernetes checks the PDB to determine if the disruption can proceed. If allowing the disruption would violate the PDB (e.g., by making too many pods unavailable), Kubernetes will delay or prevent the disruption until the budget is respected.

- **Involuntary Disruptions**: PDBs do not apply to involuntary disruptions, such as node failures or crashes. In these cases, Kubernetes will attempt to maintain availability by rescheduling pods as needed, regardless of the PDB.

### Example of a Pod Disruption Budget:

Here’s an example of a PDB that ensures at least 3 pods are always available for a deployment:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: my-app
```

### Explanation:
- **`minAvailable: 3`**: This specifies that at least 3 pods matching the label `app=my-app` must be available at all times. If there are fewer than 3 pods available, Kubernetes will not allow any voluntary disruption that would reduce the number of available pods.
- **Selector**: The PDB applies to pods labeled `app=my-app`.

### Use Cases for Pod Disruption Budgets:

1. **Ensuring High Availability**:
   - For critical applications that need to remain available, a PDB can prevent too many pods from being disrupted simultaneously, ensuring that enough instances remain to handle the load.

2. **Controlled Maintenance**:
   - During node upgrades or cluster maintenance, PDBs ensure that your application maintains sufficient availability, even as nodes are taken down and pods are rescheduled.

3. **Rolling Updates**:
   - PDBs can help manage rolling updates by ensuring that a minimum number of pods remain available while the update progresses, preventing a scenario where the application becomes temporarily unavailable during the update.

4. **Resilience Against Scaling Events**:
   - During scaling operations, such as scaling down a deployment, a PDB can prevent Kubernetes from reducing the number of running pods below a certain threshold, helping to maintain application performance and availability.

### Summary:
Pod Disruption Budgets in Kubernetes are a crucial tool for maintaining the availability and resilience of applications during planned (voluntary) disruptions. By specifying the minimum number of pods that must be available or the maximum number that can be unavailable, PDBs help ensure that your applications remain up and running, even during maintenance, upgrades, or scaling events. This is especially important for applications that require high availability or have specific uptime requirements.

## Kubernetes Storage Orchestration
Kubernetes provides a comprehensive approach to storage orchestration, allowing applications to request, consume, and manage storage resources dynamically. This system ensures that storage is abstracted and managed in a way that is consistent with Kubernetes' core principles of portability, scalability, and ease of management. Here's how Kubernetes handles storage orchestration:

### Key Components of Kubernetes Storage Orchestration:

1. **Volumes**:
   - **Definition**: A Kubernetes volume is a directory, possibly with data in it, which is accessible to containers in a pod. Unlike a container’s filesystem, the data in a volume persists beyond the life of the container.
   - **Types**:
     - **Ephemeral Volumes**: These exist as long as the pod is running (e.g., `emptyDir`, `configMap`, `secret`).
     - **Persistent Volumes (PVs)**: These are long-term storage resources that exist independently of any pod (e.g., backed by network storage like NFS, AWS EBS, GCE Persistent Disks).

2. **Persistent Volume (PV)**:
   - **Definition**: A Persistent Volume is a piece of storage in the cluster that has been provisioned by an administrator or dynamically by Kubernetes using a StorageClass. PVs are cluster resources, and they are not bound to any specific pod.
   - **Attributes**:
     - **Capacity**: Specifies the size of the PV.
     - **Access Modes**: Defines how the PV can be accessed (e.g., `ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`).
     - **Reclaim Policy**: Determines what happens to the data when a PV is released (e.g., `Retain`, `Recycle`, `Delete`).

3. **Persistent Volume Claim (PVC)**:
   - **Definition**: A Persistent Volume Claim is a request for storage by a user. It allows a pod to claim storage that meets certain requirements (e.g., size, access mode).
   - **Binding**: When a PVC is created, Kubernetes tries to find an available PV that matches the requested criteria. Once bound, the PVC is linked to that PV, and the pod can then use the storage.

4. **StorageClass**:
   - **Definition**: A StorageClass provides a way to describe the "class" of storage offered. Different classes might map to quality-of-service levels, backup policies, or arbitrary policies determined by the cluster administrators.
   - **Dynamic Provisioning**: With StorageClasses, Kubernetes can automatically provision PVs based on PVCs. This is especially useful in cloud environments where storage can be dynamically allocated (e.g., AWS EBS, GCE Persistent Disk).
   - **Attributes**:
     - **Provisioner**: Specifies the driver or plugin responsible for provisioning the storage (e.g., `kubernetes.io/aws-ebs`, `kubernetes.io/gce-pd`).
     - **Parameters**: Provides configuration details like disk type or IOPS.
     - **Reclaim Policy**: Similar to PVs, it dictates what happens when a PVC is deleted.

5. **Volume Plugins**:
   - **In-tree Plugins**: These are the volume plugins that are built into the Kubernetes core (e.g., AWS EBS, GCE PD, NFS).
   - **CSI (Container Storage Interface)**: The CSI allows storage vendors to develop plugins for Kubernetes independently of the Kubernetes release cycle. This has become the standard way to extend Kubernetes' storage capabilities with third-party drivers.

6. **Dynamic Provisioning**:
   - **Mechanism**: When a PVC is created with a specific StorageClass, Kubernetes dynamically provisions a PV that meets the requirements if one doesn’t already exist.
   - **Flexibility**: This approach provides flexibility and automation, particularly in cloud environments where storage resources can be allocated on demand.

7. **Access Modes**:
   - **ReadWriteOnce (RWO)**: The volume can be mounted as read-write by a single node.
   - **ReadOnlyMany (ROX)**: The volume can be mounted as read-only by many nodes.
   - **ReadWriteMany (RWX)**: The volume can be mounted as read-write by many nodes.

8. **Reclaim Policies**:
   - **Retain**: Keeps the data in the PV after it is released by a PVC, leaving it for manual cleanup.
   - **Recycle**: Deletes the contents of the PV but retains the PV itself, allowing it to be reused.
   - **Delete**: Deletes the PV and its associated storage when the PVC is deleted.

### Example Workflow:

1. **Define a StorageClass**:
   ```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
volumeBindingMode: WaitForFirstConsumer
#volumeBindingMode: Immediate   
   ```

2. **Create a PersistentVolumeClaim**:
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: my-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 5Gi
     storageClassName: fast
   ```

3. **Kubernetes Provisions a PV**:
   - Kubernetes matches the PVC to the `fast` StorageClass, provisions an EBS volume, and binds it to the PVC.

4. **Mount the PVC in a Pod**:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: my-pod
   spec:
     containers:
     - name: my-container
       image: my-image
       volumeMounts:
       - mountPath: "/data"
         name: my-storage
     volumes:
     - name: my-storage
       persistentVolumeClaim:
         claimName: my-pvc
   ```

### Summary:
Kubernetes manages storage orchestration by abstracting and automating the provisioning, consumption, and management of storage resources within a cluster. It uses components like Volumes, Persistent Volumes (PVs), Persistent Volume Claims (PVCs), and StorageClasses to provide dynamic and flexible storage options that can meet the diverse needs of applications. The use of the Container Storage Interface (CSI) further extends Kubernetes' storage capabilities, allowing for integration with a wide range of storage solutions. This system allows Kubernetes to handle both traditional and cloud-native storage needs effectively, supporting a wide range of workloads in different environments.
