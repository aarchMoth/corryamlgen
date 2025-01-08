#!/bin/bash
DIV_VERSION="0.1.3"
DIV_WRITTEN_FOR="BASH"

if [[ ! -e "master.wav" || ! -e "chan_c01.wav" ]]; then
    echo "You must render master audio as \"master.wav\" and channels as \"chan_c*.wav\"!"
    exit 0
fi
echo "CorrYAMLGen version ${DIV_VERSION}-${DIV_WRITTEN_FOR} (under ${OSTYPE})"
case $1 in # handle switches
    -l)
        echo "1:   PC/DA
2:   PC/DA + Sound Expansion
3:   Generic 8-Channel
4:   Generic 8-Channel (PCM)
5:   Generic 3-Channel PSG
6:   MSX + MSX-MUSIC
7:   MSX + SCC
8:   MSX + SCC+
9:   2A03
10:  AdLib
11:  Game Blaster
12:  Sound Blaster
13:  Sound Blaster w/ Game Blaster compatible
14:  Sound Blaster Pro
15:  Sound Blaster Pro 2
16:  Atari TIA"
        exit 0
    ;;
    -p)
        echo "Previewing previously generated config..."
        echo "WARNING: This script has known incompatibilities with Zsh when calling corrscope! If you are using Zsh and the preview fails, try running this script with Bash instead!"
        corr -p config.yaml
        exit 0
    ;;
    -h)
        echo "Usage: ./$(basename "$0") <system number/switch>
Switches:
-l: List systems and exit
-p: Preview a previously generated config
-h: Print this message"
    exit 0
    ;;
esac
if [[ -n $1 ]]; then
    numberIn=$1
else
    echo "Which system are you trying to render?"
    echo "1:   PC/DA
2:   PC/DA + Sound Expansion
3:   Generic 8-Channel
4:   Generic 8-Channel (PCM)
5:   Generic 3-Channel PSG
6:   MSX + MSX-MUSIC
7:   MSX + SCC
8:   MSX + SCC+
9:   2A03
10:  AdLib
11:  Game Blaster
12:  Sound Blaster
13:  Sound Blaster w/ Game Blaster compatible
14:  Sound Blaster Pro
15:  Sound Blaster Pro 2
16:  Atari TIA"
    read -p "Choose a number: " numberIn
fi
if [[ -e config.yaml ]]; then
  rm config.yaml
  touch config.yaml
fi
if [[ -z $2 || $2 != "1" ]]; then
    echo "Turn off buffer triggering?"
    read -p "" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        noBufferTrigger="1"
    fi
elif [[ -n $2 && $2 == "1" ]]; then
    noBufferTrigger="1"
else
    echo "uh excuse me what in the everfuck"
    echo "if you see this either i fucked up the code or you somehow managed to pass in a string to \$2 that neither exists or does not exist"
    exit 1
fi
read -p "Set oscilloscope amplification (or leave blank for default): " oscilloscopeAmplification
if [[ -z $oscilloscopeAmplification ]]; then
    oscilloscopeAmplification="1"
fi
echo "!Config
master_audio: master.wav
begin_time: 0
end_time:
fps: 60
trigger_ms: 60
render_ms: 40
trigger_subsampling: 1
render_subsampling: 2
render_subfps: 2
amplification: $oscilloscopeAmplification
trigger_stereo: !Flatten SumAvg
render_stereo: !Flatten SumAvg
trigger: !CorrelationTriggerConfig
  edge_direction: 1
  post_trigger:
  post_radius: 3
  mean_responsiveness: 0.0
  edge_strength: 1.0
  slope_width: 0.25" | tee -a config.yaml
if [[ $noBufferTrigger == "1" ]]; then
    echo "  buffer_strength: 0.0" | tee -a config.yaml
fi
echo "  responsiveness: 0.5
  buffer_falloff: 0.5
  reset_below: 0.3
  pitch_tracking: !SpectrumConfig {}
channels:" | tee -a config.yaml
case $numberIn in
    1)
        for i in {1..2}; do
            if [[ ! -e "./chan_c0${i}.wav" ]]; then
              echo "Channel $i was not detected."
            else
                echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Beeper (MOS 6522 VIA #$i)'" | tee -a config.yaml
            fi
        done
    ;;
    2)
        for i in {1..2}; do
            if [[ ! -e "./chan_c0${i}.wav" ]]; then
                echo "Channel $i was not detected."
            else
                echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Beeper (MOS 6522 VIA #$i)'" | tee -a config.yaml
            fi
        done
        for i in {3..5}; do
            if [[ ! -e "./chan_c0${i}.wav" ]]; then
                echo "Channel $i was not detected."
            else
                echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Square $(( i - 2 )) (TI SN76489)'" | tee -a config.yaml
            fi
        done
        if [[ ! -e "./chan_06.wav" ]]; then
            echo "Channel 6 was not detected."
        else
            echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c06.wav
  label: 'Noise (TI SN76489)'" | tee -a config.yaml
        fi
    ;;
    3)
      for i in {1..8}; do
        if [[ ! -e "./chan_c0${i}.wav" ]]; then
            echo "Channel $i was not detected."
        else
            echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $i'" | tee -a config.yaml
        fi
      done
    ;;
    4)
    for i in {1..8}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'PCM $i'" | tee -a config.yaml
    fi
    done
  ;;
    5)
    for i in {1..3}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
      echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $i'" | tee -a config.yaml
    fi
    done
    ;;
    6)
    echo "This is not tested!"
    sleep 4
    for i in {1..3}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $i (YM2149)'" | tee -a config.yaml
    fi
    done
    for i in {4..9}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'FM $(( i - 3 )) (YM2413)'" | tee -a config.yaml
    fi
    done
    for i in {10..12}; do
    if [[ ! -e "./chan_c${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c${i}.wav
  label: 'FM $(( i - 3 )) (YM2413)'" | tee -a config.yaml
    fi
    done
    ;;
    [7-8])
    for i in {1..3}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $i (YM2149)'" | tee -a config.yaml
    fi
        done
        for i in {4..8}; do
        if [[ ! -e "./chan_c0${i}.wav" ]]; then
            echo "Channel $i was not detected."
        else
            if [[ $numberIn == 8 ]]; then
                C="C+"
            else
                C="C"
            fi
            echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $(( i - 3 )) (SC$C)'" | tee -a config.yaml
        fi
        done
    ;;
    9)
    for i in {1..2}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Pulse $i'" | tee -a config.yaml
    fi
    done
    if [[ ! -e "./chan_c03.wav" ]]; then
        echo "Channel 3 was not detected."
    else
    echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c03.wav
  label: 'Triangle'" | tee -a config.yaml
    fi
    if [[ ! -e "./chan_c04.wav" ]]; then
        echo "Channel 4 was not detected."
    else
    echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c04.wav
  label: 'Noise'" | tee -a config.yaml
    fi
    if [[ ! -e "./chan_c05.wav" ]]; then
        echo "Channel 5 was not detected."
    else
    echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c05.wav
  label: 'DPCM'" | tee -a config.yaml
    fi
    ;;
    10)
    for i in {1..9}; do
    if [[ ! -e "./chan_c0${i}.wav" ]]; then
        echo "Channel $i was not detected."
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'FM $i (YM3812)'" | tee -a config.yaml
    fi
    done
    if [[ -e "${PWD}/chan_c10.wav" ]]; then
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c10.wav
  label: 'Beeper (PC Speaker)'" | tee -a config.yaml
    fi
    ;;
    11)
        i2="0"
        for i in {01..12}; do
            i2=$(( i2 + 1 ))
            if [[ $i2 -le 6 ]]; then
                echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c${i}.wav
  label: 'PSG $i2 (SAA1099 #1)'" | tee -a config.yaml
            else

                echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c${i}.wav
  label: 'PSG $(( i2 - 6 )) (SAA1099 #2)'" | tee -a config.yaml
            fi
        done
        if [[ -e "${PWD}/chan_c13.wav" ]]; then
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c13.wav
  label: 'Beeper (PC Speaker)'" | tee -a config.yaml
    fi
    ;;
    1[2-5])
        echo "nuh uh that system ain't coded yet"
        rm config.yaml
        exit 0
    ;;
    16)
        for i in {1..2}; do
        if [[ ! -e "./chan_c0${i}.wav" ]]; then
            echo "Channel $i was not detected."
        else
            echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c0${i}.wav
  label: 'Channel $i'" | tee -a config.yaml
    fi
        done
    ;;
esac
echo "default_label: !DefaultLabel FileName
layout: !LayoutConfig
  orientation: h
  nrows:
  ncols:
  stereo_orientation: v
render: !RendererConfig
  width: 1920
  height: 1080
  line_width: 4.0
  line_outline_width: 0.0
  grid_line_width: 1.0
  bg_color: '#001119'
  bg_image: ''
  init_line_color: '#00aafc'
  global_line_outline_color: '#000000'
  global_color_by_pitch: false
  pitch_colors:
  - '#ff8189'
  - '#ff9155'
  - '#ffba37'
  - '#f7ff52'
  - '#95ff85'
  - '#16ffc1'
  - '#00ffff'
  - '#4dccff'
  - '#86acff'
  - '#b599ff'
  - '#ed96ff'
  - '#ff87ca'
  grid_color: '#0074aa'
  stereo_grid_opacity: 0.25
  midline_color: '#004664'
  v_midline: true
  h_midline: true
  global_stereo_bars: true
  stereo_bar_color: '#00aafc'
  label_font: !Font
    family: Noto Sans
    bold: false
    italic: false
    size: 24.0
    toString: Noto Sans,24,-1,5,50,0,0,0,0,0,Regular
  label_position: !LabelPosition LeftTop
  label_padding_ratio: 0.5
  label_color_override:
  antialiasing: true
  res_divisor: 1.5" | tee -a config.yaml
echo "Bringing up corrscope preview..."
echo "WARNING: This script has known incompatibilities with Zsh when calling corrscope! If you are using Zsh and the preview fails, try running this script with Bash instead!"
corr -p config.yaml
echo "render to a file?"
read -p "" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rendering..."
    corr -r "./Bash Corrscope YAML Generation Test vID#$RANDOM.mp4" config.yaml
fi
echo ""
