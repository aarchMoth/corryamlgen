#!/bin/bash
shopt -s extglob
DIV_VERSION="0.1.3_FURND"
DIV_WRITTEN_FOR="BASH"
infile=$1
two=$2
FURSYSTEM=$(./furnace -info "$1" | grep "system: " | sed 's/- system: //g')
echo "CorrYAMLGen version ${DIV_VERSION}-${DIV_WRITTEN_FOR} (under ${OSTYPE})"
if [[ "$2" =~ @[-]* ]]; then # matches "-" then anything after it; detects switches
    loops=0
elif [[ -n "$2" ]]; then
    loops=$two
else
    loops=0
fi
if [[ -n "$3" ]]; then
    oscilloscopeAmplification=$3
else
    oscilloscopeAmplification="1"
fi
if [[ -z "$2" ]]; then
    thingWeShouldBeChecking=$1
else
    thingWeShouldBeChecking=$2
fi
case $thingWeShouldBeChecking in # handle switches
    -8)
        numberIn=3
    ;;
    -p)
        numberIn=4
    ;;
    -3)
        numberIn=5
    ;;
    -h)
        echo "Usage: ./$(basename "$0") [module] <loops/switches> <osc. amp.>
Switches:
-h: Print this message
-8: Render as Generic 8-Channel
-p: Render as Generic 8-Channel PCM
-3: Render as Generic 3-Channel PSG
yes this means you can't loop while using generics. whoops!"
    exit 0
    ;;
esac
if [[ -e config.yaml ]]; then
  rm config.yaml
  touch config.yaml
fi
case $FURSYSTEM in
    MegaTronics\ Inc\.\ PC\/DA)
        numberIn=1
    ;;
    MegaTronics\ Inc\.\ PC\/DA\ +\ Sound\ Expansion)
        numberIn=2
    ;;
    MSX\ +\ MSX-MUSIC)
        numberIn=6
    ;;
    MSX\ +\ SCC)
        numberIn=7
    ;;
    MSX\ +\ SCC+)
        numberIn=8
    ;;
    NES*) # "*" accounts for "NES" autofill and "NES (Ricoh 2A03)" sysdef
        numberIn=9
    ;;
    PC\ +\ AdLib)
        numberIn=10
    ;;
    Yamaha\ YM3812\ \(OPL2\))
        numberIn=10 # the AdLib generator is flexible enough to handle this, so why not?
    ;;
    PC\ @(\(barebones\)|Speaker)) # "@(\(barebones\)|Speaker)" accounts for "PC (barebones)" autofill and "PC Speaker" sysdef
        numberIn=10 # this technically works :fjpegify:
    ;;
    PC\ +\ Game\ Blaster)
        numberIn=11
    ;;
    Atari\ @(TIA*|2600/7800)) # "@(TIA*|2600/7800)" accounts for "Atari 2600/7800" autofill and "Atari TIA"/"Atari TIA (with software pitch driver)" sysdef
        numberIn=16
    ;;
    *)
        if [[ -n "$numberIn" ]]; then
            sleep 0
        else
            echo "detected system is likely not coded yet."
            exit 0
        fi
    ;;
esac
./furnace -loops $loops -outmode one -output master.wav "$infile" # render master audio
./furnace -loops $loops -outmode perchan -output chan "$infile"
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
    if [[ -e "./chan_c02.wav" ]]; then # handle PC speaker only cases
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
    else
        echo "- !ChannelConfig
  wav_path: ${PWD}/chan_c01.wav
  label: 'Beeper'" | tee -a config.yaml
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
