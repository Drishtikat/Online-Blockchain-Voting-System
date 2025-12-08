function HardwareSimulator

    %% ============================================================
    %  BASE UI CONFIG
    %% ============================================================
    fig = uifigure('Name', 'Electronic Voting Machine', ...
        'Position', [200 100 900 650], ...
        'Color', [0.97 0.97 0.97]);

    gl = uigridlayout(fig, [3, 1], ...
        'RowHeight', {'fit','fit','1x'}, ...
        'Padding', [15 15 15 15], ...
        'RowSpacing', 15);


    %% ============================================================
    %  UNIVERSAL STYLES
    %% ============================================================
    titleFont  = 16;
    labelFont  = 13;
    buttonFont = 13;
    panelColor = [1 1 1]; %color of panels - white

    btnStyle = @(b) set(b, ...
        "FontSize",buttonFont, ...
        "FontWeight","bold", ...
        "BackgroundColor",[0.15 0.45 0.85], ...
        "FontColor","white");


    %% ============================================================
    %  PUF PANEL
    %% ============================================================
    pufPanel = uipanel(gl, ...
        'Title', '   PUF Verification', ...
        'FontSize', titleFont, ...
        'FontWeight','bold', ...
        'BackgroundColor', panelColor, ...
        'BorderType','line');

    g1 = uigridlayout(pufPanel,[1 3], ...
        'ColumnSpacing',10, ...
        'Padding',10);

    uilabel(g1, "Text","Device ID:", ...
        "FontSize",labelFont, "HorizontalAlignment","right");

    devField = uieditfield(g1, "text", ...
        "Value","BU001", "FontSize",labelFont);

    btnPUF = uibutton(g1, "Text","Verify Device", ...
        "FontSize",buttonFont, ...
        "ButtonPushedFcn", @(btn,event) verifyDevice(devField.Value));
    btnStyle(btnPUF);


    %% ============================================================
    %  BIOMETRIC PANEL
    %% ============================================================
    bioPanel = uipanel(gl, ...
        'Title', '   Biometric Verification', ...
        'FontSize', titleFont, ...
        'FontWeight','bold', ...
        'BackgroundColor', panelColor);

    g2 = uigridlayout(bioPanel,[2 3], ...
        'ColumnSpacing',10, ...
        'RowSpacing',8, ...
        'Padding',10);

    uilabel(g2,"Text","Voter ID:", ...
        "FontSize",labelFont,"HorizontalAlignment","right");
    voterField = uieditfield(g2,"text", "FontSize",labelFont);

    fpStatus = uilabel(g2,"Text","", ...
        "FontSize",labelFont, ...
        "FontColor",[0 0.4 0], ...
        "HorizontalAlignment","center");
    fpStatus.Layout.Column = 3;

    uilabel(g2,"Text","Fingerprint Key:", ...
        "FontSize",labelFont,"HorizontalAlignment","right");
    fpField = uieditfield(g2,"text", "FontSize",labelFont);

    btnVerifyVoter = uibutton(g2,"Text","Verify Voter", ...
        "ButtonPushedFcn",@(btn,event) verifyVoter(), ...
        "FontSize",buttonFont);
    btnStyle(btnVerifyVoter);


    %% ============================================================
    %  BALLOT PANEL
    %% ============================================================
    ballotPanel = uipanel(gl, ...
        'Title', '   Ballot + VVPAT Unit', ...
        'FontSize', titleFont, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', panelColor);

    g3 = uigridlayout(ballotPanel,[3 2], ...
        'RowHeight', {'fit','fit','1x'}, ...
        'ColumnSpacing',12, ...
        'Padding',10);

    uilabel(g3, "Text","Select Candidate:", ...
        "FontSize",labelFont);
    candDrop = uidropdown(g3, ...
        "Items", {'BJP','INC','AAP','OTH','BSP'}, ...
        "Value", "BJP", ...
        "FontSize",labelFont);

    btnVote = uibutton(g3, "Text","Cast Vote", ...
        "Enable","off", ...
        "FontSize",buttonFont, ...
        "ButtonPushedFcn", @(btn,event) castVote());
    btnStyle(btnVote);

    btnResults = uibutton(g3, "Text","Fetch Results", ...
        "FontSize",buttonFont, ...
        "ButtonPushedFcn", @(btn,event) fetchResults());
    btnStyle(btnResults);

    vvpat = uitextarea(g3, ...
        'Editable','off', ...
        'FontSize',12, ...
        'Value',{'VVPAT Output:'});
    
    % span the full width and center align textbox
    %vvpat.Layout.Row = 3;
    %vvpat.Layout.Column = [1 2];


    %% ============================================================
    %  SIMULATED DATABASE
    %% ============================================================
    voterDB = struct('V1001','1','V1002','2','V1003','3','V1004','4','V1005','5');


    %% ============================================================
    %  CALLBACKS 
    %% ============================================================
    
    % ---------- Verify PUF ----------
    function verifyDevice(deviceId)
        try
            resp = webwrite('http://localhost:4000/verifyPUF', struct('deviceId',deviceId));

            if isfield(resp,'verified') && resp.verified
                uialert(fig, 'Device Verified', 'Success', 'Icon','success');
            else
                uialert(fig, 'Device Not Verified', 'Error', 'Icon','warning');
            end

        catch
            uialert(fig, "Cannot reach server", "Network Error", 'Icon','error');
        end
    end

    % ---------- Verify Voter ----------
    function verifyVoter()
        voterId = upper(strtrim(voterField.Value));
        fp      = strtrim(fpField.Value);
        btnVote.Enable = 'off';

        if isfield(voterDB, voterId)
            if strcmp(voterDB.(voterId), fp)
                fpStatus.Text = ['Authentication Successful: ', voterId];
                fpStatus.FontColor = [0 0.5 0];
                btnVote.Enable = 'on';
            else
                fpStatus.Text = 'Fingerprint mismatch';
                fpStatus.FontColor = [0.8 0 0];
            end
        else
            fpStatus.Text = ['Unknown ID: ', voterId];
            fpStatus.FontColor = [0.8 0 0];
        end
    end

    % ---------- Cast Vote ----------
    function castVote()
    voterId = upper(strtrim(voterField.Value));
    candidate = candDrop.Value;

    % Prepare payload
    data.voterId     = voterId;
    data.candidateId = candidate;
    data.timestamp   = char(datetime('now'));

    try
        options = weboptions('MediaType','application/json', ...
                             'RequestMethod','post', ...
                             'Timeout',10, ...
                             'CertificateFilename','');

        % ---- SEND VOTE TO BACKEND ----
        resp = webwrite('http://localhost:4000/recordVote', data, options);

        % Validate response
        if ~isfield(resp, "success") || ~resp.success
            uialert(fig, "Vote failed to record on blockchain", "Error");
            return;
        end

        % Extract returned hashes
        voterHash = "";
        if isfield(resp, "voterHash")
            voterHash = resp.voterHash;
        end

        txHash = "";
        if isfield(resp, "txHash")
            txHash = resp.txHash;
        end

        % ---- FORMAT VVPAT ----
        slip = sprintf("Voter Hash: %s\nCandidate: %s\nTime: %s\nTx Hash: %s\n", ...
                       voterHash, candidate, data.timestamp, txHash);

        % Log to file
        if ~exist('vvpat_logs','dir')
            mkdir('vvpat_logs');
        end
        writelines(slip, 'vvpat_logs/vvpat_log.txt', 'WriteMode','append');

        % Display in VVPAT box
        vvpat.Value = [vvpat.Value; "----------"; slip];

        % UI updates
        fpStatus.Text = 'Vote Recorded';
        fpStatus.FontColor = [0 0.5 0];
        btnVote.Enable = 'off';

        uialert(fig, slip, 'VVPAT', 'Icon','success');

    catch ME
        uialert(fig, sprintf("MATLAB ERROR:\n%s", ME.message), 'Error');
    end
end


    % ---------- Fetch Results ----------
    function fetchResults()
    try
        opts = weboptions('Timeout', 10, ...
                          'ContentType', 'json', ...
                          'CertificateFilename','');

        resp = webread('http://localhost:4000/getResults', opts);

        fields = fieldnames(resp);   % x1, x2, x3, x4, x5
        out = "Election Results:";
        out = [out; " "];

        for i = 1:numel(fields)
            key = fields{i};
            cName = resp.(key).name;
            count = resp.(key).voteCount;
            out = [out; sprintf("%s: %d votes", cName, count)];

            % Display voter hashes
            hashes = resp.(key).voterHashes;
            out = [out; "  Voters Hashes:"];

            for h = 1:length(hashes)
                out = [out; sprintf("%s", hashes{h})];
            end
            out = [out; " "];
        end

        vvpat.Value = [vvpat.Value; "----------"; out];

    catch ME
        uialert(fig, sprintf("MATLAB ERROR:\n%s", ME.message), "Error");
    end
end

end
