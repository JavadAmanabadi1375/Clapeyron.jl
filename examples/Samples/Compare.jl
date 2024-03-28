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
Comparison_Property="Soundspd_m_s"

# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\PhdDb.db"
db=SQLite.DB(db_path)

CompoundName="decane"
CompoundNameK=uppercasefirst(CompoundName)

    # model1 = SRK([CompoundName])
    model1 = SRK([CompoundName])
    # model2 = GERG2008([CompoundName])
    # model3 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
    # model4 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
    # model5 = PR([CompoundName])
    # model6 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    # model7 = vdW([CompoundName];idealmodel=JobackIdeal)
    # model8 = CPA([CompoundName];idealmodel=JobackIdeal)
    models = [model5];



TableName=CompoundNameK*"_"*StatePlot
condition1= StatePlot=="Isothermal" ? "Temperature_k==400" : "Pressure_MPa==20"
qs1 = "SELECT * FROM $TableName WhERE $condition1"
# qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
# qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
data1 = SQLite.DBInterface.execute(db, qs1)
df1 = DataFrames.DataFrame(data1)
x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa


p =20*1e6
T = df1.Temperature_k 
# p = df1.Pressure_MPa.*1e6
# T =  400
Cp = []
∂²A∂T²_v=[]

model_lenght=length(models)
for i ∈ 1:model_lenght

    # if i==4

    #     for f in T

    #         ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A= Gathering_Derivatives.(models[i],p,f)
    #         append!(∂²A∂T²_v,∂²A∂T²)
        
    #     end
    #     append!(Cp,[-T.*∂²A∂T²_v])

    # else
    #     append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
    # end

    append!(Cp,[speed_of_sound.(models[i],p,T)])
    # append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
    # append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
    # append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])
end

plt.clf()

qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
df_Mw = DataFrames.DataFrame(data_Mw)

xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa
# xAxix= StatePlot=="Isobaric" ? x1 : x1
yAxis=df1.Soundspd_m_s


if Comparison_Property=="Cp_J_gk"

    yAxis=(df1.Cp_J_gk.*df_Mw.Mw./R)

elseif Comparison_Property=="Cv_J_gk"

    yAxis=(df1.Cv_J_gk.*df_Mw.Mw./R)

end


# plt.plot(xAxix,Cp[1]./R,label="SRK",linestyle="-.")
# plt.plot(xAxix,Cp[2]./R,label="GERG-2008",linestyle=(0, (3, 1, 1, 1)))
# plt.plot(xAxix,Cp[3]./R,label="CK-SAFT",linestyle=(0, (5, 1)))
# plt.plot(xAxix,Cp[4]./R,label="SAFT-γ Mie",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[5]./R,label="PR",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[6]./R,label="PCSAFT",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# # plt.plot(xAxix,Cp[7]./R,label="vdW",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[8]./R,label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))

# plt.plot(xAxix,Cp[1]*(1e6),label="SRK",linestyle="-.")
# plt.plot(xAxix,Cp[2]*(1e6),label="GERG-2008",linestyle=(0, (3, 1, 1, 1)))
# plt.plot(xAxix,Cp[3]*(1e6),label="CK-SAFT",linestyle=(0, (5, 1)))
# plt.plot(xAxix,Cp[4]*(1e6),label="SAFT-γ Mie",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[5]*(1e6),label="PR",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[6]*(1e6),label="PCSAFT",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# # plt.plot(xAxix,Cp[7]*(1e6),label="vdW",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[8]*(1e6),label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))

plt.plot(xAxix,Cp[1],label="SRK",linestyle="-.")
plt.plot(xAxix,Cp[2],label="GERG-2008",linestyle=(0, (3, 1, 1, 1)))
plt.plot(xAxix,Cp[3],label="CK-SAFT",linestyle=(0, (5, 1)))
plt.plot(xAxix,Cp[4],label="SAFT-γ Mie",linestyle=(0, (3, 1, 1, 1, 1, 1)))
plt.plot(xAxix,Cp[5],label="PR",linestyle=(0, (3, 1, 1, 1, 1, 1)))
plt.plot(xAxix,Cp[6],label="PCSAFT",linestyle=(0, (3, 1, 1, 1, 1, 1)))
# plt.plot(xAxix,Cp[7],label="vdW",linestyle=(0, (3, 1, 1, 1, 1, 1)))
plt.plot(xAxix,Cp[8],label="CPA",linestyle=(0, (3, 1, 1, 1, 1, 1)))


plt.plot(xAxix,yAxis,label="experimental","o",color="k")


if Comparison_Property=="Cp_J_gk"

    plt.ylabel("Cp/R",fontsize=16)


elseif Comparison_Property=="Cv_J_gk"

    plt.ylabel("Cv/R",fontsize=16)

else

    # plt.ylabel("$Comparison_Property",fontsize=16)
    plt.ylabel("u (m/s)",fontsize=16)

end
xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
plt.xlabel(xlabelName,fontsize=16)

plt.legend(loc="upper right",frameon=false,fontsize=10)
# plt.title(condition1*" "* CompoundNameK)
# plt.xlim([0.3,9])
# plt.ylim([-1,1])
display(plt.gcf())


for i ∈ 1:model_lenght

    # ABSOLUTE RELATIVE DEVIATION
    if Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

        exp_values=(df1.Cp_J_gk.*df_Mw.Mw)
    
    else

        exp_values=df1.JouleThomson_K_MPa
        
    end
        # # Find the index of NaN value
        # non_nan_indices = [j for (j, x) in enumerate(Cp[i]) if isnan(x)]
        # foreach(reverse(non_nan_indices)) do y
        #     deleteat!(Cp[i], y)
        #     deleteat!(exp_values, y)

        # end


    ARD = abs.((Cp[i]) - (exp_values))
    # AVERAGE ABSOLUTE RELATIVE DEVIATION
    AARD = 100 * abs.(mean((ARD ./ (exp_values))))
    print(CompoundName*" model=$i"," %AARD = ",AARD)
    print("\n")
end



