name<-c("DstL","DstM","DstA","GldL","GldM","GldA","BluL","BluM","BluA","DiaL","DiaM","DiaA")
qty<-c(150,500,800,173,246,321,15,25,40,60,100,150)
Dval<-0.26
Gval<-0.035
Bval<-2.6
value<-c(Dval,Dval,Dval,Gval,Gval,Gval,Bval,Bval,Bval,1,1,1)
V<-qty*value
p<-c(0.3375,0.03,0.0075,0.3375,0.03,0.0075,0.1125,0.01,0.0025,0.1125,0.01,0.0025)
sum(V*p)


reroll<-function(e,z,k,ev1,i){ev2<-c(ev1,e);z2<-z[(1+(i-1)*k):(i*k)]
for(j in k:2){z3<-z2[which(z2<ev2[j])];a<-length(z3)
if(a==j){return(sum(z2)+max(0,a*ev2[j]-sum(z3)-50))}}
return(sum(z2))}


EVGK<-function(m,mm,k,ev1){e1<-max(ev1);e2<-max(V)
while(e2-e1>0 || n<m){s1<-0;s2<-0;n<-min(mm,max(10,round(10000/abs(e2-e1))))
for(i in 1:n){z<-sample(V,2*k,replace=T,prob=p)
s1<-s1+reroll(e1,z,k,ev1,1);s2<-s2+reroll(e2,z,k,ev1,2)}
e1<-s1/(n*k);e2<-s2/(n*k)}
return(c(ev1,(e1+e2)/2))}


EVGG<-function(m,mm,n){ev1<-c(sum(V*p))
for(i in 2:n){ev1<-EVGK(m,mm,i,ev1);print(ev1)}
return(ev1)}


EVGG(20000,1000000,10)