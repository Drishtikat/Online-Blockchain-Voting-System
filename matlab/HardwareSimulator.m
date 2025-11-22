function HardwareSimulator

    fig = uifigure('Name', 'Electronic Voting Machine', 'Position', [100 100 800 600]);
    gl = uigridlayout(fig, [3, 1], 'RowHeight', {'fit','fit','1x'}, 'Padding', 10);

    %% ============================================================
    %  PUF PANEL
    %% ============================================================
    pufPanel = uipanel(gl, 'Title', 'PUF Verification', 'FontWeight','bold');
    g1 = uigridlayout(pufPanel,[1,3]);

    uilabel(g1,"Text","Device ID:");
    devField = uieditfield(g1,"text","Value","BU001");
    uibutton(g1,"Text","Verify Device",...
        "ButtonPushedFcn", @(btn,event) verifyDevice(devField.Value));

    %% ============================================================
    %  BIOMETRIC PANEL
    %% ============================================================
    bioPanel = uipanel(gl, 'Title', 'Biometric Verification', 'FontWeight','bold');
    g2 = uigridlayout(bioPanel,[2,3]);

    uilabel(g2,"Text","Voter ID:");
    voterField = uieditfield(g2,"text");
    fpStatus = uilabel(g2,"Text","","FontColor",[0 0.5 0]);

    uilabel(g2,"Text","Fingerprint Key:");
    fpField = uieditfield(g2,"text");
    btnVerifyVoter = uibutton(g2,"Text","Verify Voter", ...
        "ButtonPushedFcn",@(btn,event) verifyVoter());

    fpStatus.Layout.Column = 3;

    %% ============================================================
    %  BALLOT PANEL
    %% ============================================================
    ballotPanel = uipanel(gl, 'Title', 'Ballot Unit + VVPAT', 'FontWeight','bold');
    g3 = uigridlayout(ballotPanel,[3,2],'RowHeight',{'fit','fit','1x'});

    uilabel(g3,"Text","Select Candidate:");
    candDrop = uidropdown(g3,"Items",{'BJP','INC','AAP','OTH','BSP'},"Value","BJP");

    btnVote = uibutton(g3,"Text","Vote","Enable","off", ...
        "ButtonPushedFcn",@(btn,event) castVote());

    uibutton(g3,"Text","Fetch Results",...
        "ButtonPushedFcn",@(btn,event) fetchResults());

    vvpat = uitextarea(g3,'Editable','off','Value',{'VVPAT Display:'});

    %% Simulated DB
    voterDB = struct('V1001','1','V1002','2','V1003','3','V1004','4','V1005','5');

    %% ============================================================
    %  CALLBACKS
    %% ============================================================

    % ---------- Verify PUF ----------
    function verifyDevice(deviceId)
        try
            data = struct('deviceId', deviceId);

            resp = webwrite('http://localhost:4000/verifyPUF', data);

            if isfield(resp,'verified') && resp.verified
                uialert(fig, 'Device Verified!', 'Success');
            else
                uialert(fig,'Device Not Verified!','Error');
            end

        catch ME
            uialert(fig,"Cannot reach server!","Network Error");
            disp(ME.message);
        end
    end

    % -------- Verify Voter --------
    function verifyVoter()
        voterId = upper(strtrim(voterField.Value));
        fp = strtrim(fpField.Value);
        btnVote.Enable = 'off';

        if isfield(voterDB, voterId)
            if strcmp(voterDB.(voterId), fp)
                fpStatus.Text = ['✔ Voter Verified: ', voterId];
                fpStatus.FontColor = [0 0.5 0];
                btnVote.Enable = 'on';
            else
                fpStatus.Text = '❌ Fingerprint mismatch';
                fpStatus.FontColor = [0.8 0 0];
            end
        else
            fpStatus.Text = ['❌ Unknown ID: ', voterId];
            fpStatus.FontColor = [0.8 0 0];
        end
    end

    % -------- Cast Vote --------
    function castVote()
        voterId = upper(strtrim(voterField.Value));
        candidate = candDrop.Value;

        % Prepare JSON
        data.voterId = voterId;
        data.candidateId = candidate;
        data.timestamp = char(datetime('now'));
        data.hashVoter = matlab.net.base64encode(voterId);
        data.hashCand = matlab.net.base64encode(candidate);

        try
            options = weboptions('MediaType','application/json', ...
                                 'RequestMethod','post', ...
                                 'Timeout',10, ...
                                 'CertificateFilename','');

            resp = webwrite('http://localhost:4000/recordVote', data, options);

            if isstruct(resp)
                if isfield(resp,"success") && resp.success
                    disp("Vote recorded successfully");
                else
                    disp("Unexpected JSON response:");
                    disp(resp);
                end
            else
                disp("Backend returned raw text:");
                disp(resp);
            end


            % Logging
            if ~exist('vvpat_logs','dir')
                mkdir('vvpat_logs');
            end

            slip = sprintf("Voter: %s\nCandidate: %s\nTime: %s\n", ...
                data.hashVoter, data.hashCand, data.timestamp);

            writelines(slip,'vvpat_logs/vvpat_log.txt','WriteMode','append');
            vvpat.Value = [vvpat.Value; "----"; slip];

            fpStatus.Text = '✔ Vote Recorded!';
            fpStatus.FontColor = [0 0.5 0];
            btnVote.Enable = 'off';

            uialert(fig, slip, 'VVPAT');

        catch ME
            uialert(fig,'Could not send vote to server','Network Error');
            disp(ME.message);
        end
    end

    % -------- Fetch Results --------
    function fetchResults()
        try
            resp = webread('http://localhost:4000/getResults');
            disp(resp);

            out = "Election Results:";
            keys = {'BJP','INC','AAP','OTH','BSP'};

            for i = 1:5
                cName = resp.(sprintf('%d',i)).name;
                count = resp.(sprintf('%d',i)).voteCount;
                out = [out; sprintf("%s: %d votes", cName, count)];
            end

            vvpat.Value = [vvpat.Value; "==== RESULTS ===="; out];

        catch ME
            uialert(fig,'Cannot fetch results','Error');
            disp(ME.message);
        end
    end

end
% End of HardwareSimulator.m