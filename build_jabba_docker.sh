docker run -it --rm --platform linux/amd64 mskilab/jabba:latest 

 docker cp gurobi10.0.3_linux64.tar.gz f62ebffb16f1:/opt/gurobi.tar.gz
 #/opt/gurobi1103/linux64
 ##IN docker
 cd /opt
 tar -zxvf gurobi.tar.gz
 rm gurobi.tar.gz
 export GUROBI_HOME="/opt/gurobi1003/linux64"
 export LD_LIBRARY_PATH="/opt/gurobi1003/linux64/lib"
 R
 install.packages("slam")
 install.packages("/opt/gurobi1003/linux64/R/gurobi_10.0-3_R_4.2.0.tar.gz",repos=NULL,type="source")




docker commit --change="ENV GUROBI_HOME=/opt/gurobi1003/linux64 LD_LIBRARY_PATH=/opt/gurobi1003/linux64/lib" f62ebffb16f1 dnousome/jabba:v0.0.1 

docker run -it --rm  --mount type=bind,src="$(pwd)",target=/src --platform linux/amd64 dnousome/jabba:v0.0.1 

R
library(JaBbA)
JaBbA("/src/coerced_chr_TCGA-2F-A9KP-01A.gripss.filtered.vcf.gz","/src/coerced_chr_cov.rds",use.gurobi=T)



docker push dnousome/jabba:v0.0.1
