
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="L" #You can choose either Isobaric or Isothermal
CompoundName="heptane"

# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\RegionsT.db"
db=SQLite.DB(db_path)

# Open the Excel file
file_path="C:\\Users\\javam\\OneDrive - Danmarks Tekniske Universitet\\PhD\\Packages\\Clapeyron\\Clapeyron.jl\\examples\\Samples\\AARDF.xlsx"


db_pathT= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\PhDdb.db"
dbT=SQLite.DB(db_pathT)

Tr=[0.7]

plt.clf()
fig_alph, ax_alph = plt.subplots(figsize=[12, 9])

foreach(Tr) do Temperature

    CompoundNameK=uppercasefirst(CompoundName)

    model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :KG,cubicmodel=RK,alpha=SoaveAlpha)
    model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    model4 = SAFTVRMie([CompoundName];idealmodel=JobackIdeal)
    model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)

    models = [model1,model2,model3,model4,model5];
    model_lenght=length(models)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)
    df_Mw_Tc_k=df_Mw.Tc_k[1]

    TableName=CompoundNameK*"_"*StatePlot
    condition1= StatePlot=="L" ? "Round(Temperature_k / $df_Mw_Tc_k,2)==$Temperature" : "Pressure_MPa==20"
    qs1 = "SELECT * FROM $TableName WhERE $condition1"
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa
    p = df1.Pressure_MPa.*1e6
    T=df1.Temperature_k[1]

    conditionT= "Pressure_MPa==20"
    qsT = "SELECT * FROM Heptane_Isobaric WhERE $conditionT"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
    dataT = SQLite.DBInterface.execute(dbT, qsT)
    dfT = DataFrames.DataFrame(dataT)

    p = 20*1e6
    T=dfT.Temperature_k
    xAxis=T

    ∂²A∂T²_v=[]
    ∂²A∂V∂T_v=[]
    ∂²A∂V²_v=[]
    ∂²A∂T²_v=[]
    ∂A∂V_v=[]
    ∂A∂T_v=[]
    ∂p∂V_v=[]
    ∂p∂T_v=[]
    A_v=[]

    for i=1:model_lenght

       dA= Gathering_Res_Derivatives.(models[i],p,T)
       append!(∂A∂V_v,[[dA[i][6] for i ∈ 1:length(T)]])

    end

    ax_alph.plot(xAxis./df_Mw_Tc_k,∂A∂V_v[1]*1e-6,label="SRK",linestyle="--",color="g",linewidth=2)
    ax_alph.plot(xAxis./df_Mw_Tc_k,∂A∂V_v[2]*1e-6,label="CPA",linestyle="-.",color="b",linewidth=2)
    ax_alph.plot(xAxis./df_Mw_Tc_k,∂A∂V_v[3]*1e-6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
    ax_alph.plot(xAxis./df_Mw_Tc_k,∂A∂V_v[5]*1e-6,label="SAFT-γ Mie",color="k",linewidth=2)
    ax_alph[:set_xlabel]("Tr",fontsize=14)
    ax_alph[:set_ylabel]("\$∂A^{res}∂V\\:(J\\:\\cdot K^{-1}\\cdot m^{3})\\cdot 1e6\$",fontsize=14)
    ax_alph.legend(loc="upper left",frameon=false,fontsize=10)

    display(plt.gcf())


end
# plt.savefig("∂A∂V.pdf")



