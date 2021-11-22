# load libraries
library(DSOpal)
library(dsSyntheticClient)
library(dsBaseClient)

# build a login to the server
builder <- DSI::newDSLoginBuilder()

# login details
# includes the table we want to look at and simulate data from (DASIM.DASIM1)
#builder$append(server="server1", url="https://opal-sandbox.mrc-epid.cam.ac.uk",
#               user="dsuser", password="password", 
#               table = "DASIM.DASIM1")

#builder$append(server="server1", url="https://opal-demo.obiba.org",
#               user="dsuser", password="password", 
#               table = "DASIM.DASIM1")

# as using local test containers, disable ssl verification
httr::set_config(httr::config(ssl_verifypeer = 0L))

builder$append(server="server1", url="https://localhost:8843",
               user="administrator", password="password", 
               table = "DASIM.DASIM1", profile = "default")

logindata <- builder$build()

# establish a connection to the server
if(exists("connections")){
  datashield.logout(conns = connections)
}
connections <- datashield.login(logins=logindata, assign = TRUE)

# have a look at some summary statistics for the DASIM.DASIM1 dataset
ds.ls(datasources = connections)
# get a summary for the 'D' object (default name, to which DASIM.DASIM1 is assigned)
ds.summary(x = 'D', datasources = connections)

# get a summary of the mean, number of rows and quantiles for the 'LAB_GLUC_FASTING' variable
ds.summary(x = 'D$LAB_GLUC_FASTING', datasources = connections)

# generate a table of gender and BMI categories
 ds.table('D$GENDER', 'D$PM_BMI_CATEGORICAL', newobj = 'gender_bmi', datasources = connections)

# generate some synthetic data from the DASIM.DASIM1 table
synth_data <- ds.syn(data = "D", method = "cart", m = 1, seed = 123, datasources = connections)$server1$syn

# we then have the synthetic data on the client side and can view and manipulate it as required
head(synth_data)

# disclosure control examples

# simple example - turn the continuous BMI variable into a factor
ds.asFactor(input.var.name = "D$PM_BMI_CONTINUOUS", newobj.name = "D$PM_BMI_BADFACTOR", datasources = connections)
# fails - 10000 rows with unique levels
datashield.errors()

# subset with a BMI > 30
ds.dataFrameSubset(df.name = "D", 
                   V1.name = "D$PM_BMI_CONTINUOUS", 
                   V2.name = "30", Boolean.operator = ">",  
                   newobj = "D.BMI.over30", 
                   datasources = connections)
ds.summary(x = "D.BMI.over30", datasources = connections)

# table of diabetes status and gender
ds.table(rvar = "D.BMI.over30$DIS_DIAB", cvar = "D.BMI.over30$GENDER", datasources = connections)

# subset with a BMI > 40
ds.dataFrameSubset(df.name = "D", 
                   V1.name = "D$PM_BMI_CONTINUOUS", 
                   V2.name = "40", Boolean.operator = ">",  
                   newobj = "D.BMI.over40", 
                   datasources = connections)
ds.summary(x = "D.BMI.over40", datasources = connections)

# however - try to create a table of those with diabetes and gender...
ds.table(rvar = "D.BMI.over40$DIS_DIAB", cvar = "D.BMI.over40$GENDER", datasources = connections)
# fails as one cell count < 3

# now try a subset with BMI > 50
ds.dataFrameSubset(df.name = "D", 
                   V1.name = "D$PM_BMI_CONTINUOUS", 
                   V2.name = "50", 
                   Boolean.operator = ">",  
                   newobj = "D.BMI.over50", 
                   datasources = connections)
# fails - too few rows
datashield.errors()

# histograms for comparison
# synthetic data
hist(synth_data$PM_BMI_CONTINUOUS)
# live data (non-disclosive histogram)
ds.histogram(x = "D$PM_BMI_CONTINUOUS", num.breaks = 20, datasources = connections)

# logout
datashield.logout(connections)
