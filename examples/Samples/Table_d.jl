
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="L" #You can choose either Isobaric or Isothermal
Comparison_Property=["dPdT","dPdV","Density_Kg_m3","Psat"]
# Comparison_Property=["Psat"]

# Comparison_Compound=["ethane","propane","butane","pentane","hexane","heptane","octane","nonane","decane"]
# Comparison_Compound=["nonane","decane"]
Comparison_Compound=["methane"]
ModelNames=["SRK","PR","CPA","CK-SAFT","PC-SAFT",
            "SAFT-VR Mie (2013)","SAFT-γ-Mie","GERG (2008)"]


# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\RegionsT.db"
db=SQLite.DB(db_path)


# Open the Excel file
file_path="C:\\Users\\javam\\OneDrive - Danmarks Tekniske Universitet\\PhD\\Packages\\Clapeyron\\Clapeyron.jl\\examples\\Samples\\AARDF.xlsx"


global  cellNo=6

foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"

    model1 = SRK([CompoundName];idealmodel=WalkerIdeal)
    model2 = PR([CompoundName];idealmodel=WalkerIdeal)
    model3 = CPA([CompoundName];idealmodel=WalkerIdeal,radial_dist = :CS,cubicmodel=RK,alpha=SoaveAlpha)
    model4 = CKSAFT([CompoundName];idealmodel=WalkerIdeal)
    model5 = PCSAFT([CompoundName];idealmodel=WalkerIdeal)
    model6 = SAFTVRMie([CompoundName];idealmodel=WalkerIdeal)
    model7 = SAFTgammaMie([CompoundName];idealmodel=WalkerIdeal)
    model8 = GERG2008([CompoundName])

    models = [model1,model2,model3,model4,model5,model6,model7,model8];
    model_lenght=length(models)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)
    df_Mw_Tc_k=df_Mw.Tc_k[1]

    TableName=CompoundNameK*"_"*StatePlot
    condition1= StatePlot=="L" ? "Round(Temperature_k / $df_Mw_Tc_k,2)==0.5" : "Pressure_MPa==20"
    qs1 = "SELECT * FROM $TableName WhERE $condition1"
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

    # p =20*1e6
    # T = df1.Temperature_k 
    p = df1.Pressure_MPa.*1e6
    T=df1.Temperature_k[1]
 
    #-----------------dPdV, dPdT NIST data---

    dPdV=((df1.Soundspd_m_s.*df1.Soundspd_m_s).*(df_Mw.Mw./1000).*(df1.Cv_J_molk))./
    ((df1.Cp_J_molk).*(-df1.Volume_L_mol.*df1.Volume_L_mol).*1e-6)
    dPdT=(-((((df1.Cp_J_molk.-df1.Cv_J_molk).+R).*(dPdV))./(T))).^0.5
    #----------------------------------------

    foreach(Comparison_Property) do property
        
        for i ∈ 3:3
            
            ∂²A∂T²_v=[]
            Cp = []
            sat = []
            ∂²A∂V∂T_v=[]
            ∂²A∂V²_v=[]
            ∂²A∂T²_v=[]
            ∂A∂V_v=[]
            ∂A∂T_v=[]
            ∂p∂V_v=[]
            ∂p∂T_v=[]
            A_v=[]


            for f in p
    
                ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A= Gathering_Derivatives.(models[i],f,T,vol0=4.053258655186213e-05)
                # ahs,adisp,achain,aassociation=a_res_gathering.(models[i],f,T)
                append!(∂p∂V_v,∂p∂V)
                append!(∂p∂T_v,∂p∂T)
                append!(∂²A∂V∂T_v,∂²A∂V∂T)
                append!(∂²A∂V²_v,∂²A∂V²)
                append!(∂A∂V_v,∂A∂V)
                append!(∂A∂T_v,∂A∂T)
                append!(∂²A∂T²_v,∂²A∂T²)
                append!(A_v,A)

            end
            
            if property=="dPdT"

                Cp=∂p∂T_v
                exp_values=dPdT
                # CPA Model results ------------------------------------
                # TableNameC=CompoundNameK*"_"*"CPA"
                # qs_CERE = "SELECT * FROM $TableNameC"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.dPdT
                #-------------------CPA Model results---------------------


                if i==1
                    sheetname="H"
 
                elseif i==2 
                    sheetname="L"

                elseif i==3
                    sheetname="P"

                elseif i==4
                    sheetname="T"

                elseif i==5
                    sheetname="X"

                elseif i==6
                    sheetname="AF"

                elseif i==7
                    sheetname="AJ"

                elseif i==8
                    sheetname="AN"

                end
    
            elseif property=="dPdV"

                Cp=∂p∂V_v
                exp_values=dPdV

                # CPA Model results ------------------------------------
                # TableNameC=CompoundNameK*"_"*"CPA"
                # qs_CERE = "SELECT * FROM $TableNameC"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.dPdV
                #-------------------CPA Model results---------------------

                if i==1
                    sheetname="I"
 
                elseif i==2 
                    sheetname="M"

                elseif i==3
                    sheetname="Q"

                elseif i==4
                    sheetname="U"

                elseif i==5
                    sheetname="Y"

                elseif i==6
                    sheetname="AG"

                elseif i==7
                    sheetname="AK"

                elseif i==8
                    sheetname="AO"

                end
    
            elseif property=="Density_Kg_m3"
    
    
                Cp=molar_density.(models[i],p,T,vol0=4.053258655186213e-05)
                # exp_values=df1.Density_Kg_m3.*1000/(df_Mw.Mw)
                exp_values=df1.Density_mol_L*1e3

                    # CPA Model results ------------------------------------
                    # TableNameC=CompoundNameK*"_"*"CPA"
                    # qs_CERE = "SELECT * FROM $TableNameC"
                    # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                    # df_CERE = DataFrames.DataFrame(data_CERE)
                    # Cp=df_CERE.Ro
                    #-------------------CPA Model results---------------------

                if i==1
                    sheetname="J"
 
                elseif i==2 
                    sheetname="N"

                elseif i==3
                    sheetname="R"

                elseif i==4
                    sheetname="V"

                elseif i==5
                    sheetname="Z"

                elseif i==6
                    sheetname="AH"

                elseif i==7
                    sheetname="AL"

                elseif i==8
                    sheetname="AP"

                end
    
            elseif property=="Psat"

                # TableNameC=CompoundNameK*"_"*"CPA"
                # qs_CERE = "SELECT * FROM $TableNameC"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.Psat

                TableName=CompoundNameK*"_"*"SatL"
                qs_sat="SELECT * FROM $TableName"
                data_sat = SQLite.DBInterface.execute(db, qs_sat)
                df_sat = DataFrames.DataFrame(data_sat)
                exp_values=df_sat.Pressure_MPa*1e6    #change to MPa
                sat = saturation_pressure.(models[i],df_sat.Temperature_k)
                Cp=[x[1] for x in sat]

                if i==1
                    sheetname="K"
 
                elseif i==2 
                    sheetname="O"

                elseif i==3
                    sheetname="S"

                elseif i==4
                    sheetname="W"

                elseif i==5
                    sheetname="AA"

                elseif i==6
                    sheetname="AI"

                elseif i==7
                    sheetname="AM"

                elseif i==8
                    sheetname="AQ"

                end
    
            end

                # # Find the index of NaN value
                non_nan_indices = [j for (j, x) in enumerate(Cp) if (isnan(x) || isinf(x))]
                foreach(reverse(non_nan_indices)) do y
                    deleteat!(Cp, y)
                    deleteat!(exp_values, y)
    
                end
                
                # ABSOLUTE RELATIVE DEVIATION       
                ARD = abs.((Cp) - (exp_values))
    
                # AVERAGE ABSOLUTE RELATIVE DEVIATION
                AARD = 100 * abs.(mean((ARD ./ abs.(exp_values))))
    
                    XLSX.openxlsx(file_path, mode="rw") do xf
    
                        sheet=xf[1]
    
                        sheet[sheetname*"$cellNo"]=AARD
                    
                    end

        end

    end
    
   global  cellNo += 1
end


