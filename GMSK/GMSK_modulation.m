function m_filtered2 = GMSK_modulation(signal,sps, Tb) 

    signal = 2*signal-1;

    rect = upsample(signal,sps); 

    % create gaussian low pass filter(defined in the gaussian_filter.m)
    gaussfilter = GMSK_gaussian_filter(Tb,sps);

    % pass message signal through Gaussian LPF
    m_filtered = conv(rect,gaussfilter,'same');
    %m_filtered = [m_filtered ;m_filtered(length(m_filtered))]; % add extra sample at end.
    
    m_filtered1 = cumsum(m_filtered); % integrate the data.
    
    m_filtered2_real = cos(m_filtered1);
    m_filtered2_imag = sin(m_filtered1);
    m_filtered2 = m_filtered2_real + 1i*m_filtered2_imag;
end