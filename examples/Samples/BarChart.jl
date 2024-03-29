# This script are calculate thermophysical properties based on different EOS
# using Pkg
# Pkg.activate("..")
# print(@__FILE__)
# print("\n")


using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
import PyPlot; const plt = PyPlot
using Plots


const  R =8.314 #J/mole*k

# Comparison_Compound=["Methane","Ethane","Propane","Butane","Pentane","Hexane","Heptane","Octane","Nonane","Decane"]
# Comparison_Compound=["Pentane"]
StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property="Cp_J_gk"

# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\PhdDb.db"
db=SQLite.DB(db_path)

CompoundName="ethane"
CompoundNameK=uppercasefirst(CompoundName)

    # model1 = SRK([CompoundName])
    model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    model2 = JobackIdeal([CompoundName])
    model3 = GERG2008([CompoundName])
    model4 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
    model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
    model6 = PR([CompoundName];idealmodel=JobackIdeal)
    model7 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    # model9 = PR([CompoundName];)
    model8 = vdW([CompoundName];idealmodel=JobackIdeal)
    model9 = CPA([CompoundName];idealmodel=JobackIdeal)
    models = [model1,model2,model3,model4,model5,
            model6,model7,model8,model9];



TableName=CompoundNameK*"_"*StatePlot
condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==2"
qs1 = "SELECT * FROM $TableName WhERE $condition1"
# qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
data1 = SQLite.DBInterface.execute(db, qs1)
df1 = DataFrames.DataFrame(data1)
x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa


# p =2*1e6
# T = df1.Temperature_k 
p = df1.Pressure_MPa.*1e6
T =  300
Cp = []
∂²A∂V∂T_v=[]
∂²A∂V²_v=[]
∂²A∂T²_v=[]
∂A∂V_v=[]
∂A∂T_v=[]
∂p∂V_v=[]
∂p∂T_v=[]

model_lenght=length(models)
for i ∈ 1:model_lenght
    # append!(Cp,[speed_of_sound.(models[i],p,T)])
    # append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
    append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
    # append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])
    # ∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,∂p∂V=Gathering_Derivatives.(models[i],p,T)
    # append!(∂²A∂V∂T_v,[∂²A∂V∂T])
    # append!(∂²A∂V²_v,[∂²A∂V²])
    # append!(∂²A∂T²_v,[∂²A∂T²])
    # append!(∂A∂V_v,[∂A∂V])
    # append!(∂A∂T_v,[∂A∂T])
    # append!(∂p∂V_v,[∂p∂V])
end
# for i ∈ 1:model_lenght
    for f in p

    ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T= Gathering_Derivatives.(models[9],f,T)
    append!(∂p∂V_v,∂p∂V)
    append!(∂p∂T_v,∂p∂T)
    append!(∂²A∂V∂T_v,∂²A∂V∂T)
    append!(∂²A∂V²_v,∂²A∂V²)
    append!(∂A∂V_v,∂A∂V)
    append!(∂A∂T_v,∂A∂T)
    append!(∂²A∂T²_v,∂²A∂T²)


    end
  
# end


plt.clf()

qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
df_Mw = DataFrames.DataFrame(data_Mw)

xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa
# xAxix= StatePlot=="Isobaric" ? x1 : x1
yAxis=df1.JouleThomson_K_MPa


if Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

    yAxis=(df1.Cp_J_gk.*df_Mw.Mw./R)

end



# ModelNames=["NIST","SRK","JobackIdeal","GERG2008","CKSAFT","SAFTgammaMie","PR","PC-SAFT","VdW","CPA"]
# CvValues=[mean(yAxis),mean(Cp[1])./R,mean(Cp[2])./R,mean(Cp[3])./R,mean(Cp[4])./R,mean(Cp[5])./R,mean(Cp[6])./R,mean(Cp[7])./R,mean(Cp[8])./R,mean(Cp[9])./R]
# colors = ["red","blue", "blue", "blue", "blue","blue","blue","blue","blue","blue"]
# xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
# bar(ModelNames, CvValues,color=colors ,xlabel="Model", ylabel="Cv/R", title="Bar Chart Example",xtickfontsize=5)

# ModelNames=["∂²A∂T²","∂²A∂V∂T","∂²A∂V²"]
labels = ["Parameter $i" for i in 1:length(xAxix)]
bar(labels, Cp[1]./R,xlabel="Model", ylabel="Cv/R", title="Bar Chart Example",xtickfontsize=5)







