
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot
using Plots
using Unitful
using LaTeXStrings

const  R =8.314 #J/mole*k

# Comparison_Compound=["Propane","Pentane","Heptane","Decane"]
Comparison_Compound=["propane"]
StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property="Cv_J_gk"

# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\AlkanesSR.db"
db=SQLite.DB(db_path)

# Open the Excel file
file_path="C:\\Users\\javam\\ClapeyronNew\\Clapeyron.jl\\examples\\Samples\\Ares.xlsx"

plt.clf()
foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)

    # model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    # model2 = JobackIdeal([CompoundName])
    # model3 = GERG2008([CompoundName])
    # model4 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
    # model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
    # model6 = PR([CompoundName];idealmodel=JobackIdeal)
    # model7 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    # model8 = vdW([CompoundName];idealmodel=JobackIdeal)
    # model9 = CPA([CompoundName];idealmodel=JobackIdeal)
    # models = [model1,model2,model3,model4,
    #         model6,model7,model8,model9];

    # model1 = vdW([CompoundName];idealmodel=JobackIdeal)
    # model2 = SRK([CompoundName];idealmodel=JobackIdeal)
    # model3 = PR([CompoundName];idealmodel=JobackIdeal)
    # model4 = CPA([CompoundName];idealmodel=JobackIdeal)
    # model5 = GERG2008([CompoundName])
    # model6 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
    if CompoundName=="Methane"

        model7 = SAFTgammaMie([CompoundName];idealmodel=WalkerIdeal)
        TableName=CompoundNameK*"_"*StatePlot
        condition1= StatePlot=="Isothermal" ? "Temperature_k==190" : "Pressure_MPa==2"
        T=190
    else

        TableName=CompoundNameK*"_"*StatePlot
        condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==2"
        model7 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
        T=300
    end
    # model7 = SAFTgammaMie([CompoundName];idealmodel=WalkerIdeal)

    # model8 = SAFTVRMie([CompoundName];idealmodel=JobackIdeal)
    models = [model7];
    model_lenght=length(models)


   
    qs1 = "SELECT * FROM $TableName"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 

    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    # x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

    # qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundName'" 
    # data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    # df_Mw = DataFrames.DataFrame(data_Mw)

    # p =2*1e6
    # T = df1.Temperature_k 
    p = df1.Pressure_MPa.*1e6
    # T =  100

    # xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa
    xAxix=df1.Pressure_MPa

    # ModelNames=["SRK","JobackIdeal","GERG2008","CKSAFT","SAFTgammaMie","PR","PC-SAFT","VdW","CPA"]
    # ModelNames=["VdW","SRK","PR","CPA","GERG2008","CKSAFT","SAFTgammaMie","SAFTVRMie"]
    ModelNames=["SAFTgammaMie"]
   
    global  cellNo=8
    for i ∈ 1:model_lenght

        ∂²A∂V∂T_v=[]
        ∂²A∂V²_v=[]
        ∂²A∂T²_v=[]
        ∂A∂V_v=[]
        ∂A∂T_v=[]
        ∂p∂V_v=[]
        ∂p∂T_v=[]
        A_v=[]
        ahs_V=[]
        adisp_V=[]
        achain_V=[]
        aassociation_V=[]
        AresT=[]

        for f in p

            ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A= Gathering_Derivatives.(models[i],f,T)
            ahs,adisp,achain,aassociation=a_res_gathering.(models[i],f,T)
            append!(∂p∂V_v,∂p∂V)
            append!(∂p∂T_v,∂p∂T)
            append!(∂²A∂V∂T_v,∂²A∂V∂T)
            append!(∂²A∂V²_v,∂²A∂V²)
            append!(∂A∂V_v,∂A∂V)
            append!(∂A∂T_v,∂A∂T)
            append!(∂²A∂T²_v,∂²A∂T²)
            append!(A_v,A)
            append!(ahs_V,ahs)
            append!(adisp_V,adisp)
            append!(achain_V,achain)
            # append!(aassociation_V,aassociation)
            append!(AresT,aassociation+achain+ahs+adisp)

            # XLSX.openxlsx(file_path, mode="rw") do xf

            #     sheet=xf[1]

            #     sheet["H"*"$cellNo"]=CompoundNameK
            #     sheet["AG"*"$cellNo"]=ahs
            #     sheet["AH"*"$cellNo"]=achain
            #     sheet["AI"*"$cellNo"]=adisp
            #     sheet["AJ"*"$cellNo"]=aassociation
            #     sheet["M"*"$cellNo"]=aassociation+achain+ahs+adisp
            #     sheet["F"*"$cellNo"]=f
            #     sheet["G"*"$cellNo"]=T
            
            # end
            global  cellNo += 1
        end

        plt.plot(xAxix,ahs_V,label=ModelNames[i],linestyle=(0, (3, 1, 1, 1)))
        # plt.plot(xAxix,∂p∂V_v.*1e-12,label="SAFT-γ-Mie",linestyle=(0, (3, 1, 1, 1)))
        # plt.plot(xAxix,achain_V,label=ModelNames[i]*"$CompoundNameK"*"Achain",linestyle=(0, (3, 1, 1, 1)))
        # plt.plot(xAxix,df1.dPdV_GPa_liter,label="NIST","o",color="k")

        xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
        plt.xlabel("Pr",fontsize=16)
        # plt.ylabel("∂P/∂V",fontsize=16)
        plt.ylabel("dP/dV [GPa/liter]",fontsize=16)
        plt.legend(loc="upper right",frameon=false,fontsize=8)
        # plt.title(condition1*" "*"$CompoundNameK")
        display(plt.gcf())
    end



end
    






