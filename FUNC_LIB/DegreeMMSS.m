%Extract LAT LONG data to Degree.Decimal
clear all
close all

%  Auto-generated by MATLAB on 17-May-2012 16:54:47
cd 'C:\PVK_Projects\3582_Rio_Tinto\data';


count=1;
DELIMITER = ' ';
HEADERLINES = 0;


% Import the file
newData1 = importdata('Bingham 2008 2010.txt', DELIMITER, HEADERLINES);
fid=fopen('stations_DDddd.txt','w');
% Create new variables in the base workspace from those fields.
vars = fieldnames(newData1);
for i = 1:length(vars)
    assignin('base', vars{i}, newData1.(vars{i}));
end


for ii=1:size(data,1)
    datapoints(count,1)=data(ii,1)-data(ii,2)/60-data(ii,1)/3600;
    datapoints(count,2)=data(ii,4)+data(ii,5)/60+data(ii,6)/3600;
    datastation{count}=rowheaders{ii};
    
    fprintf(fid,'%4.0fd%2.0fm%5.3fs,%2.0fd%2.0fm%5.3fs,%2.1f\n',...
        data(ii,1),data(ii,2),data(ii,3),data(ii,4),data(ii,5),data(ii,6),0.0);
count=count+1;
end

% Import the file
newData1 = importdata('HT_Stockton_2009.txt', DELIMITER, HEADERLINES);

% Create new variables in the base workspace from those fields.
vars = fieldnames(newData1);
for i = 1:length(vars)
    assignin('base', vars{i}, newData1.(vars{i}));
end


for ii=1:size(data,1)
    datapoints(count,1)=data(ii,1)-data(ii,2)/60-data(ii,1)/3600;
    datapoints(count,2)=data(ii,4)+data(ii,5)/60+data(ii,6)/3600;
    datastation{count}=rowheaders{ii};
    
        fprintf(fid,'%4.0fd%2.0fm%5.3fs,%2.0fd%2.0fm%5.3fs,%2.1f\n',...
        data(ii,1),data(ii,2),data(ii,3),data(ii,4),data(ii,5),data(ii,6),0.0);
    count=count+1;
end

% Import the file
newData1 = importdata('Quantec_Bingham2007.txt', DELIMITER, HEADERLINES);

% Create new variables in the base workspace from those fields.
vars = fieldnames(newData1);
for i = 1:length(vars)
    assignin('base', vars{i}, newData1.(vars{i}));
end


for ii=1:size(data,1)
    datapoints(count,1)=data(ii,1)-data(ii,2)/60-data(ii,1)/3600;
    datapoints(count,2)=data(ii,4)+data(ii,5)/60+data(ii,6)/3600;
    datastation{count}=rowheaders{ii};
        fprintf(fid,'%4.0fd%2.0fm%5.3fs,%2.0fd%2.0fm%5.3fs,%2.1f\n',...
        data(ii,1),data(ii,2),data(ii,3),data(ii,4),data(ii,5),data(ii,6),0.0);
    count=count+1;
    
end

% Import the file
newData1 = importdata('Quantec_RoseCanyon_2009.txt', DELIMITER, HEADERLINES);

% Create new variables in the base workspace from those fields.
vars = fieldnames(newData1);
for i = 1:length(vars)
    assignin('base', vars{i}, newData1.(vars{i}));
end


for ii=1:size(data,1)
    datapoints(count,1)=data(ii,1)-data(ii,2)/60-data(ii,1)/3600;
    datapoints(count,2)=data(ii,4)+data(ii,5)/60+data(ii,6)/3600;
    datastation{count}=rowheaders{ii};
    
        fprintf(fid,'%4.0fd%2.0fm%5.3fs,%2.0fd%2.0fm%5.3fs,%2.1f\n',...
        data(ii,1),data(ii,2),data(ii,3),data(ii,4),data(ii,5),data(ii,6),0.0);
count=count+1;
end

% Import the file
newData1 = importdata('Settlement Canyon_2009.txt', DELIMITER, HEADERLINES);

% Create new variables in the base workspace from those fields.
vars = fieldnames(newData1);
for i = 1:length(vars)
    assignin('base', vars{i}, newData1.(vars{i}));
end


for ii=1:size(data,1)
    datapoints(count,1)=data(ii,1)-data(ii,2)/60-data(ii,1)/3600;
    datapoints(count,2)=data(ii,4)+data(ii,5)/60+data(ii,6)/3600;
    datastation{count}=rowheaders{ii};
    
        fprintf(fid,'%4.0fd%2.0fm%5.3fs,%2.0fd%2.0fm%5.3fs,%2.1f\n',...
        data(ii,1),data(ii,2),data(ii,3),data(ii,4),data(ii,5),data(ii,6),0.0);
count=count+1;
end
fclose(fid);