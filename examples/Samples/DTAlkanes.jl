
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
# Comparison_Property=["Cp_J_gk","Cv_J_gk","JouleThomson_K_MPa","Soundspd_m_s"]
Comparison_Property=["Cp_J_gk"]

Comparison_Compound=["ethane","propane","butane","pentane","hexane","heptane","octane","nonane","decane"]
# Comparison_Compound=["ethane","propane"]
# Comparison_Compound=["pentane"]
T=[300,400,500]
ModelNames=["SRK","JobackIdeal","GERG2008","CKSAFT","SAFTgammaMie","PR","PC-SAFT","VdW","CPA"]


# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\AlkanesSR.db"
db=SQLite.DB(db_path)


# Open the Excel file
file_path="C:\\Users\\javam\\ClapeyronNew\\Clapeyron.jl\\examples\\Samples\\AARD.xlsx"

global  cellNo=7

foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)

    foreach(Comparison_Property) do property


        # model1 = SRK([CompoundName];idealmodel=JobackIdeal)
        # model2 = JobackIdeal([CompoundName])
        # model3 = GERG2008([CompoundName])
        # model4 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
        # model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
        # model6 = PR([CompoundName];idealmodel=JobackIdeal)
        # model7 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
        # model8 = vdW([CompoundName];idealmodel=JobackIdeal)
        # model9 = CPA([CompoundName];idealmodel=JobackIdeal)
        # models = [model1,model2,model3,model4,model5,
        #         model6,model7,model8,model9];

        model7 =  SAFTVRMie([CompoundName];idealmodel=JobackIdeal)
        models=[model7]

        model_lenght=length(models)


        TableName=CompoundNameK*"_"*StatePlot
        condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==2"
        # qs1 = "SELECT * FROM $TableName WhERE $condition1"
        qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
        data1 = SQLite.DBInterface.execute(db, qs1)
        df1 = DataFrames.DataFrame(data1)
        x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

        qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
        data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
        df_Mw = DataFrames.DataFrame(data_Mw)


        # p =2*1e6
        # T = df1.Temperature_k 
        p = df1.Pressure_MPa.*1e6
        T=300
        Cp = []

        if property=="Cp_J_gk"

            for i ∈ 1:model_lenght

                append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])

            end
            sheetname="AQ"
            exp_values=(df1.Cp_J_gk.*df_Mw.Mw)

        elseif property=="Cv_J_gk"

            for i ∈ 1:model_lenght

                append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])

            end
            sheetname="AP"
            exp_values=(df1.Cv_J_gk.*df_Mw.Mw)

        elseif property=="JouleThomson_K_MPa"

            for i ∈ 1:model_lenght

                append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])

            end
            sheetname="AO"
            exp_values=(df1.JouleThomson_K_MPa*(1e-6))

        elseif property=="Soundspd_m_s"

            for i ∈ 1:model_lenght

                append!(Cp,[speed_of_sound.(models[i],p,T)])

            end
            sheetname="AR"
            exp_values=(df1.Soundspd_m_s)

        end

        
        for i ∈ 1:model_lenght
            # Find the index of NaN value
            non_nan_indices = [j for (j, x) in enumerate(Cp[i]) if isnan(x)]
            foreach(reverse(non_nan_indices)) do y
                deleteat!(Cp[i], y)
                deleteat!(exp_values, y)

            end
           
            # ABSOLUTE RELATIVE DEVIATION       
            ARD = abs.((Cp[i]) - (exp_values))

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


