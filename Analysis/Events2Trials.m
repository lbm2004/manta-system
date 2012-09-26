function T = Events2Trials(varargin)

P = parsePairs(varargin); %NAF 9/2: changed to varargin to allow for optional Runclass input.

if isfield(P,'Events') Events = P.Events; end
if isfield(P,'Stimclass') Stimclass = P.Stimclass; end
if isfield(P,'TimeIndex') TimeIndex = P.TimeIndex; end

Notes = lower({Events.Note});

%Index variables give the index in the event data for each index type
%speciifed in the variable name
TrialInd = find(strcmp('trialstart',Notes));
PreSilenceInd   = find(~cellfun(@isempty,strfind(Notes,'prestimsilence')));
PostSilenceInd = find(~cellfun(@isempty,strfind(Notes,'poststimsilence')));
OutcomeInd    = find(~cellfun(@isempty,strfind(Notes,'outcome')));
StimInd = find(~cellfun(@isempty,strfind(Notes,'stim ,')));

%Initialize trial vectors
T.Indices = NaN*zeros(size(TrialInd));
T.Durations = NaN*zeros(size(TrialInd));
T.Tags = cell(size(TrialInd));

%try
if TimeIndex
    T.Indices = [1:length(TrialInd)];
    T.SortInd = [1:length(TrialInd)];
    [tmp,T.SortInd] = sort(T.Indices,'ascend');
else
    switch lower(Stimclass)
        case {'torcs','torc'};
            for i=1:length(TrialInd)
                Inds = find(Notes{StimInd(i)}==',');
                T.Tags{i} = Notes{StimInd(i)}(Inds(1)+2:Inds(2)-2);
                cInd = find(T.Tags{i}=='_');
                T.Indices(i) = str2num(T.Tags{i}(cInd(2)+1:cInd(3)-1));
                T.Durations(i) = Events(StimInd(i)).StopTime - Events(StimInd(i)).StartTime;
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case {'pure tones','randomtone','amtone'};
            for i=1:length(TrialInd)
                Inds = find(Notes{StimInd(i)}==',');
                T.Tags{i} = Notes{StimInd(i)}(Inds(1)+2:Inds(2)-2);
                T.Frequencies(i) = str2num(Events(StimInd(i)).Note(Inds(1)+1:Inds(2)-1));
                T.Durations(i) = Events(StimInd(i)).StopTime - Events(StimInd(i)).StartTime;
            end
            [tmp,T.SortInd] = sort(T.Frequencies);
            [tmp,tmp,IndicesLoc] = unique(T.Frequencies);
            IndicesSet = [1:length(tmp)];
            T.Indices = IndicesSet(IndicesLoc);
            T.FrequenciesByIndex = unique(T.Frequencies);
            
        case 'tuningfast'; % although multiple stimuli are within one trial, here only the indices are returned
            error('Not tested or seriously implemented yet');
            for i=1:length(TrialInd)     k=0; Found = 0;
                if i<length(TrialInd) NextInd = TrialInd(i+1)-1; else NextInd = length(Events); end;
                while k+TrialInd(i) <= NextInd
                    tmp = strfind(Events(TrialInd(i)+k).Note,'Tone');
                    if ~isempty(tmp) Found = 1; break; else k=k+1; end;
                end
                FirstStimTag = Events(TrialInd(i)+k).Note;
                cInd = find(FirstStimTag==' ');
                T.Indices(i) = str2num(FirstStimTag(cInd(3)+1:cInd(4)-1));
                T.Tags{i} = FirstStimTag(cInd(2)+1:cInd(4)-1);
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'biasedshepardpair';
            for i=1:length(TrialInd)     k=0; Found = 0;
                if ~isempty(OutcomeInd)
                    T.Outcomes{i} = Notes{OutcomeInd(i)}(9:end);
                    switch T.Outcomes{i}
                        case 'match'; T.OutcomesNum(i) = 1;
                        case 'miss';   T.OutcomesNum(i) = 0;
                        case 'early';   T.OutcomesNum(i) = -1;
                        case 'vearly'; T.OutcomesNum(i) = -2;
                    end
                end
                if i<length(TrialInd) NextInd = TrialInd(i+1)-1; else NextInd = length(Events); end;
                while k+TrialInd(i) <= NextInd
                    tmp = strfind(Events(TrialInd(i)+k).Note,'ShepardTone');
                    if ~isempty(tmp) Found = 1; break; else k=k+1; end;
                end
                if Found
                    FirstStimTag = Events(TrialInd(i)+k).Note;
                    cInd = find(FirstStimTag==' ');
                    T.Indices(i) = str2num(FirstStimTag(cInd(3)+1:cInd(4)-1));
                    T.Tags{i} = FirstStimTag(cInd(2)+1:cInd(4)-1);
                    % T.Durations(i) = Events(PostSilenceInd(i)).StartTime ...
                    %- Events(PreSilenceInd(i)).StopTime;
                else
                    T.Indices(i) = NaN;
                    T.Tags{i} = '';
                    T.Durations(i) = NaN;
                end
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            if ~isfield(T,'OutcomesNum') T.OutcomesNum = ones(size(T.Indices)) ; end
            
        case 'shepardtuning';
            for i=1:length(TrialInd)     k=0; Found = 0;
                if i<length(TrialInd) NextInd = TrialInd(i+1)-1; else NextInd = length(Events); end;
                while k+TrialInd(i) <= NextInd
                    tmp = strfind(Events(TrialInd(i)+k).Note,'ShepardTone');
                    if ~isempty(tmp) Found = 1; break; else k=k+1; end;
                end
                FirstStimTag = Events(TrialInd(i)+k).Note;
                cInd = find(FirstStimTag==' ');
                T.Indices(i) = str2num(FirstStimTag(cInd(3)+1:cInd(4)-1));
                T.Tags{i} = FirstStimTag(cInd(2)+1:cInd(4)-1);
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'biasedshepardtuning'
            for i=1:length(TrialInd)  k=0; Found = 0;
                if i<length(TrialInd) NextInd = TrialInd(i+1)-1; else NextInd = length(Events); end;
                while k+TrialInd(i) <= NextInd
                    tmp = strfind(Events(TrialInd(i)+k).Note,'ShepardTone');
                    if ~isempty(tmp) Found = 1; break; else k=k+1; end;
                end
                FirstStimTag = Events(TrialInd(i)+k).Note;
                cInd = find(FirstStimTag==' ');
                T.Indices(i) = str2num(FirstStimTag(cInd(3)+1:cInd(4)-1));
                T.Tags{i} = FirstStimTag(cInd(2)+1:cInd(4)-1);
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'ferretvocal'
            for i=1:length(TrialInd)
                Inds = find(Notes{StimInd(i)}==',');
                T.Tags{i} = Notes{StimInd(i)}(Inds(1)+2:Inds(2)-2);
                T.Durations(i) = Events(StimInd(i)).StopTime - Events(StimInd(i)).StartTime;
            end
            [tmp,SortInd] = sort(T.Tags); % Generate unique order for the tags
            T.Indices = SortInd;
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'tstuning'
            for i=1:length(TrialInd)
                Inds = find(Notes{StimInd(i)}==',');
                T.Tags{i} = Notes{StimInd(i)}(Inds(1)+2:Inds(2)-2);
                cInd = find(Notes{StimInd(i)}=='-');
                T.Frequencies(i) = str2num(Events(StimInd(i)).Note(Inds(1)+1:cInd-1));
                T.Attenuations(i) = str2num(Events(StimInd(i)).Note(cInd:Inds(2)-1));
                T.Durations(i) = Events(StimInd(i)).StopTime - Events(StimInd(i)).StartTime;
            end
            T.FrequenciesUnique = unique(T.Frequencies);
            T.AttenuationsUnique = unique(T.Attenuations);
            i=0;
            for iF=1:length(T.FrequenciesUnique)
                for iA = 1:length(T.AttenuationsUnique)
                    i=i+1;
                    T.ParametersByIndex(i,:) =  [T.FrequenciesUnique(iF),T.AttenuationsUnique(iA)];
                end
            end
            T.TrialsByParameters = cell(length(T.FrequenciesUnique),length(T.AttenuationsUnique));
            for i=1:length(TrialInd)
                for j=1:length(TrialInd)
                    if T.ParametersByIndex(j,1) == T.Frequencies(i)  ...
                            && T.ParametersByIndex(j,2) == T.Attenuations(i)
                        break;
                    end
                end
                T.Indices(i) = j;  % Indices By Trials
                iF = find(T.Frequencies(i)==T.FrequenciesUnique);
                iA = find(T.Attenuations(i)==T.AttenuationsUnique);
                T.TrialsByParameters{iF,iA}(end+1) = i;
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'speechlong'
            for i=1:length(TrialInd)
                cStimInd = StimInd(find(StimInd>TrialInd(i),1,'first'));
                StartInd = find(Notes{cStimInd}==':')+1;
                StopInd = find(Notes{cStimInd}=='+')-1;
                T.Loudnesses(i) = str2num(Notes{cStimInd}(StartInd:StopInd));
            end
            T.Loudnesses(isnan(T.Loudnesses)) = inf;
            Loudnesses = sort(unique(T.Loudnesses));
            
            for i=1:length(Loudnesses)
                T.Indices(T.Loudnesses == Loudnesses(i)) = i;
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'rhythm'
            for i=1:length(TrialInd)
                Inds = find(Notes{StimInd(i)}==',');
                T.Tags{i} = Notes{StimInd(i)}(Inds(1)+2:Inds(2)-2);
                cInd = find(T.Tags{i}==' ');
                T.Indices(i) = str2num(T.Tags{i}(cInd(1)+1:end));
                T.Durations(i) = Events(StimInd(i)).StopTime - Events(StimInd(i)).StartTime;
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'monauralhuggins'
            for i=1:length(TrialInd)
                StartInd = strfind(Notes{StimInd(i)},'huggins')+8;
                StopInd = find(Notes{StimInd(i)}=='-')-1;
                T.Indices(i) = str2num(Notes{StimInd(i)}(StartInd:StopInd));
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        case 'spnoise'
            [UNotes,tmp,Inds] = unique(Notes(StimInd));
            for iI=1:length(UNotes)
                T.Indices(find(Inds==iI)) = iI;
            end
            [tmp,T.SortInd] = sort(T.Indices,'ascend');
            
        otherwise
            dbquit    warning('Stimclass not implemented!');
            T.SortInd = [1:length(TrialInd)];
            
    end
end
    % catch
    %   T.Indices = [1:length(TrialInd)];
    %   T.SortInd = [1:length(TrialInd)];
    % end
    %
    T.NIndices = length(unique(T.Indices));