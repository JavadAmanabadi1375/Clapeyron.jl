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


const  R =8.314 #J/mole*k

# Comparison_Compound=["Methane","Ethane","Propane","Butane","Pentane","Hexane","Heptane","Octane","Nonane","Decane"]
# Comparison_Compound=["Pentane"]
StatePlot="Isobaric" #You can choose either Isobaric or Isothermal
Comparison_Property="JouleThomson_K_MPa"

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


p =2*1e6
T = df1.Temperature_k 
# p = df1.Pressure_MPa.*1e6
# T =  300
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
    # append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
    append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])
    # ∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,∂p∂V=Gathering_Derivatives.(models[i],p,T)
    # append!(∂²A∂V∂T_v,[∂²A∂V∂T])
    # append!(∂²A∂V²_v,[∂²A∂V²])
    # append!(∂²A∂T²_v,[∂²A∂T²])
    # append!(∂A∂V_v,[∂A∂V])
    # append!(∂A∂T_v,[∂A∂T])
    # append!(∂p∂V_v,[∂p∂V])
end
# for i ∈ 1:model_lenght
    for f in T
    ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T= Gathering_Derivatives.(models[9],p,f)
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

    yAxis=(df1.Cv_J_gk.*df_Mw.Mw./R)

end


# plt.plot(xAxix,Cp[2],label="JobackIdeal",linestyle=":")
# plt.plot(xAxix,Cp[1],label="SRK",linestyle="-.")
# plt.plot(xAxix,Cp[3],label="GERG-2008",linestyle=(0, (3, 1, 1, 1)))
# plt.plot(xAxix,Cp[4],label="CK-SAFT",linestyle=(0, (5, 1)))
# plt.plot(xAxix,Cp[5],label="SAFT-γ Mie",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[6],label="PR",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[7],label="PCSAFT",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[8],label="vdW",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[9],label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))

# plt.plot(xAxix,Cp[2]*(1e6),label="JobackIdeal",linestyle=":")
# plt.plot(xAxix,Cp[1]*(1e6),label="SRK",linestyle="-.")
# plt.plot(xAxix,Cp[3]*(1e6),label="GERG-2008",linestyle=(0, (3, 1, 1, 1)))
# plt.plot(xAxix,Cp[4]*(1e6),label="CK-SAFT",linestyle=(0, (5, 1)))
# plt.plot(xAxix,Cp[5]*(1e6),label="SAFT-γ Mie",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[6]*(1e6),label="PR",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[7]*(1e6),label="PCSAFT",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[8]*(1e6),label="vdW",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[9]*(1e6),label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,yAxis,label="experimental","o",color="k")

plt.plot(xAxix,∂p∂T_v,label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))

if Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

    plt.ylabel("Cv/R",fontsize=16)


else

    plt.ylabel("$Comparison_Property",fontsize=16)

end
xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
plt.xlabel(xlabelName,fontsize=16)

plt.legend(loc="upper right",frameon=false,fontsize=6)
plt.title(condition1*" "* CompoundNameK)
# plt.xlim([0.1,0.6])
# plt.ylim([-0.00001,0.00011])
display(plt.gcf())


for i ∈ 1:model_lenght

    # ABSOLUTE RELATIVE DEVIATION
    if Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

        exp_values=(df1.Cv_J_gk.*df_Mw.Mw)
    
    else

        exp_values=df1.JouleThomson_K_MPa
        
    end
    ARD = abs.((Cp[i]*1e6) - (exp_values))
    # AVERAGE ABSOLUTE RELATIVE DEVIATION
    AARD = 100 * abs.(mean((ARD ./ (exp_values))))
    print(CompoundName*" model=$i"," %AARD = ",AARD)
    print("\n")
end



