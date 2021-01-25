# tpcds_spark_docker_slurm

# Short description:
tpcds_spark_docker_slurm provides an automated way to run "TPCDS like" benchmarks on a dynamically created Spark cluster that runs in Docker containers 
across multiple SLURM nodes.

# Requirements:
1) Working SLURM environment with GPU support
2) Docker and NVIDIA container toolkit installed on the SLURM nodes
3) Shared file storage shared across all SLURM nodes, the cloned repo needs to be on shared storage for the script to work. (S3 supported for data sets)
4) Support to exclusively use SLURM nodes allowing the "--network host" option in Docker
5) Sudo access rights on SLURM nodes
6) SLURM Heterogeneous Job Support. The master will use a different group to prevent allocating valuable resources that will not be used or running on the same node.

# Preparation:
1) Git clone this repository on a node with access to the SLURM environment
      - https://github.com/eddojansen/tpcds_spark_docker_slurm.git
2) Build your own Docker images or use the ones already provided, more Docker image details below
3) Generate or use existing TPCDS datasets on file or s3, set DATAGEN="false" or "true" accordingly 
4) Adjust start-container-on-slurm.script to match the resources available in your environment 
  and adjust the settings for testing, more details below

# Usage:
1) To submit the "TPCDS like" workload to the SLURM environment run: sbatch start-container-on-slurm.script
2) When a job is accepted it will get a job number and create a log file for that job in the current directory
3) After the job has succesfully finished the containers will be shutdown and removed
4) The TPCDS result files, test config, spark history and SLURM logs will be collected in the current directory with the SLURM batch job ID as prefix

# start-container-on-slurm.script:
1) Adjust #SBATCH slurm resources as needed.The first resources group is for the master, the second for the workers. Do not change the ntasks per node.
2) Update Dowbload URL's and JAR names as required
3) Provide mount-point for shared filesystem for config
3) Enable test data generation when needed with "true" or "false" (still needs some manual input, not finished yet)
4) Enable or disable GPU with "true" or "false" (not finished yet)
5) Set threads per GPU
6) Set INPUT and OUTPUTH path for file or s3 (aws or gcp)

# Docker images:
1) tcpds_spark_docker_slurm uses the following 2 Docker images:  
      - gcr.io/data-science-enterprise/spark-master-slurm:3.0.1
      - gcr.io/data-science-enterprise/spark-worker-slurm:3.0.1
2) The Spark master container will be run on the first SLURM node
3) The Spark worker container will be run on all other nodes (excluding the first SLURM node)
4) The ${MOUNT} variable will be mapped to /data in both containers
5) The master Docker image has the following specs:
      - Ubuntu 18.04 based image
      - Spark installed locally in /opt/spark
6) The worker Docker image has the following specs:
      - nvidia/cuda:11.0-runtime-ubuntu18.04 based image
      - S3 related jars placed in /opt/spark/jars during Docker image build
      - Spark installed locally in /opt/spark
      - GPU related jars and scripts mapped via ${MOUNT}/sparkRapidsPlugin and ${MOUNT}/tpcds

# Building your own Docker images:
1) The following Dockerfiles are included in the repository:
      - Dockerfile-spark-master-tpcds
      - Dockerfile-spark-worker-rapids-tpcds
2) Follow the Dockerfile examples and ensure the following is present in the Docker build location:
      - Extracted spark installation
3) Build images with:
      - docker build -t gcr.io/data-science-enterprise/spark-master-tpcds:x.x.x -f Dockerfile-spark-master-tpcds --network host .
4) Push images with:
      - docker push gcr.io/data-science-enterprise/spark-master-tpcds:3.0.1

# Logic:
1) SLURM will allocate available nodes and resources
2) Required configuration folders will be created on the configured shared storage mountpoint
3) wait-worker.sh, kill-master.sh, kill-worker.sh, sparkRapidsPlugin and tpcds will be copied to fixed locations on $MOUNT
4) Any old running Docker instances for master will be killed on the first SLURM node
5) Any old running docker instances for worker will be killed on all other SLURM nodes
6) Cache will be dropped and cleared on all SLURM nodes
7) Hostnames for all SLURM nodes that participate in the job will be added to the mountpoint/conf/slaves file
8) Default Spark setting will be added to mountpoint/conf/spark-defaults.conf
9) When needed master docker image can first be removed from first SLURM node (not enabled by default)
10) Run Spark master docker container on first SLURM node with:
      - mapped spark-defaults.conf
      - mapped history
      - mapped results
      - mapped ${MOUNT}
      - network host
11) When needed worker docker image can be first removed from all SLURM nodes (not enabled by default)
12) Run Spark worker docker container on all SLURM nodes with:
      - mapped spark-defaults.conf
      - mapped history
      - mapped results
      - mapped ${MOUNT}
      - network host
13) Wait until all workers have been registered with the master
14) Run the datagen job if enabled
15) Run the TPCDS job as configured
16) Kill master instance on first SLURM node
17) Kill worker instance on all other SLURM nodes
18) Collect results in local folder
