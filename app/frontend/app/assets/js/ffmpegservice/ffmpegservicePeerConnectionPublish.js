/*
 * This code and all components (c) Copyright 2019-2020, Ffmpegservice Media Systems, LLC. All rights reserved.
 * This code is licensed pursuant to the BSD 3-Clause License.
 */

let browserDetails = window.adapter.browserDetails;

// munge plug-in
let mungeSDP = undefined;

// callbacks
let onconnectionstatechange = undefined;
let onstop = undefined;
let onerror = undefined;

// local state
let localStream = undefined;
let streamInfo = undefined;
let mediaInfo = {
  videoBitrate: "",
  audioBitrate: "",
  videoFrameRate: "30",
  videoCodec: "42e01f",
  audioCodec: "opus"
}
let userData = undefined;
let statsInterval = undefined;

let wsConnection = undefined;
let peerConnection = undefined;
let peerConnectionConfig = { 'iceServers': [] };
peerConnectionConfig = null;
let videoSender = undefined;
let audioSender = undefined;


function gotIceCandidate(event) {
  if (event.candidate != null) {
    console.log('FfmpegservicePeerConnectionPublish.gotIceCandidate: ' + JSON.stringify({ 'ice': event.candidate }));
  }
}

function gotDescription(description) {
  console.log("FfmpegservicePeerConnectionPublish.gotDescription: SDP:");
  console.log(description.sdp+'');

  let mungeData = new Object();

  if (mediaInfo.audioBitrate != null)
    mungeData.audioBitrate = mediaInfo.audioBitrate;
  if (mediaInfo.videoBitrate != null)
    mungeData.videoBitrate = mediaInfo.videoBitrate;
  if (mediaInfo.videoFrameRate != null)
    mungeData.videoFrameRate = mediaInfo.videoFrameRate;
  if (mediaInfo.videoCodec != null)
    mungeData.videoCodec = mediaInfo.videoCodec;
  if (mediaInfo.audioCodec != null)
    mungeData.audioCodec = mediaInfo.audioCodec;

  if (mungeSDP != null)
  {
    description.sdp = mungeSDP(description.sdp, mungeData);
  }

  console.log("FfmpegservicePeerConnectionPublish.gotDescription: Setting local description SDP: ");
  console.log(description.sdp);


  peerConnection
    .setLocalDescription(description)
    .then(() => {
      wsConnection.send('{"direction":"publish", "command":"sendOffer", "streamInfo":' +
        JSON.stringify(streamInfo) +
        ', "sdp":' +
        JSON.stringify(description) +
        ', "userData":' +
        JSON.stringify(userData) + '}');
    })
    .catch((error)=>{
      let newError = {message:"Peer connection failed",...error};
      errorHandler(newError);
    });
}

function createOnStats(onStats) {
  return () => {
    if (peerConnection != null)
    {
      peerConnection.getStats(null)
      .then(onStats, err => console.log(err));
    }
  }
}

function wsConnect(url) {
  try
  {
    wsConnection = new WebSocket(url);
  }
  catch(e)
  {
    errorHandler(e);
    return;
  }

  wsConnection.binaryType = 'arraybuffer';

  wsConnection.onopen = function () {
    console.log("FfmpegservicePeerConnectionPublish.wsConnection.onopen");

    peerConnection = new RTCPeerConnection(peerConnectionConfig);
    videoSender = undefined;
    audioSender = undefined;

    peerConnection.onicecandidate = (event) => {
      if (event.candidate != null) {
        console.log('FfmpegservicePeerConnectionPublish.gotIceCandidate: ' + JSON.stringify({ 'ice': event.candidate }));
      }
    }

    peerConnection.onconnectionstatechange = (event) => {
      if (onconnectionstatechange != null)
      {
        onconnectionstatechange(event);
      }
    }

    peerConnection.onnegotiationneeded = (event) => {
      peerConnection.createOffer(gotDescription, errorHandler);
    }

    if(localStream) {
      let localTracks = localStream?.getTracks();
      for (let localTrack in localTracks) {
        let sender = peerConnection.addTrack(localTracks[localTrack], localStream);
        if (localTracks[localTrack].kind === 'audio')
        {
          audioSender = sender;
        }
        else if (localTracks[localTrack].kind === 'video')
        {
          videoSender = sender;
        }
      }
    }
    else {
      setTimeout(() => {
        let localTracks = localStream?.getTracks();
        for (let localTrack in localTracks) {
          let sender = peerConnection.addTrack(localTracks[localTrack], localStream);
          if (localTracks[localTrack].kind === 'audio')
          {
            audioSender = sender;
          }
          else if (localTracks[localTrack].kind === 'video')
          {
            videoSender = sender;
          }
        }
      }, 5000)
    }
  }

  wsConnection.onmessage = function (evt) {
    console.log("FfmpegservicePeerConnectionPublish.wsConnection.onmessage: " + evt.data);

    var msgJSON = JSON.parse(evt.data);

    var msgStatus = Number(msgJSON['status']);
    var msgCommand = msgJSON['command'];

    if (msgStatus != 200) {
      stop();
      errorHandler({message:msgJSON['statusDescription']});
    }
    else {
      var sdpData = msgJSON['sdp'];
      if (sdpData !== undefined) {

        var mungeData = new Object();

        if (mediaInfo.audioBitrate !== undefined)
          mungeData.audioBitrate = mediaInfo.audioBitrate;
        if (mediaInfo.videoBitrate !== undefined)
          mungeData.videoBitrate = mediaInfo.videoBitrate;

        console.log("FfmpegservicePeerConnectionPublish.wsConnection.onmessage: Setting remote description SDP:");
        console.log(sdpData.sdp);

        peerConnection
          .setRemoteDescription(new RTCSessionDescription(sdpData),
            () => { },
            errorHandler
          );
      }

      var iceCandidates = msgJSON['iceCandidates'];
      if (iceCandidates !== undefined) {
        for (var index in iceCandidates) {
          console.log('FfmpegservicePeerConnectionPublish.wsConnection.iceCandidates: ' + iceCandidates[index]);
          peerConnection.addIceCandidate(new RTCIceCandidate(iceCandidates[index]));
        }
      }
    }
  }

  wsConnection.onclose = function () {
    console.log("FfmpegservicePeerConnectionPublish.wsConnection.onclose");
  }

  wsConnection.onerror = function (error) {
    console.log('wsConnection.onerror');
    console.log(error);
    let message = "Websocket connection failed: " + url;
    console.log(message);
    let newError = {message:message,...error};
    stop();
    errorHandler(newError);
  }
}

function replaceTrack (type, newTrack)
{
  if (peerConnection != null)
  {
    if (type === 'audio')
    {
      if (audioSender != null)
      {
        audioSender.replaceTrack(newTrack);
      }
      else
      {
        audioSender = peerConnection.addTrack(newTrack);
      }
    }
    else if (type === 'video')
    {
      if (videoSender != null)
      {
        videoSender.replaceTrack(newTrack);
      }
      else
      {
        videoSender = peerConnection.addTrack(newTrack);
      }
    }
  }
}

// startProps:
//   wsURL: string
//   localStream: MediaStream
//   streamInfo: { applicationName, streamName }
//   mediaInfo: { videoBitrate, audioBitrate, videoFrameRate, videoCodec, audioCodec }
//   userData: any
//   mungeSDP: function (sdpStr, mungeData)
//   onconnectionstatechange: function
//   onerror: function

function start (props)
{
  let wsURL = props.wsURL;
  localStream = props.localStream;
  if (props.streamInfo != null)
    streamInfo = props.streamInfo;
  if (props.mediaInfo != null)
    mediaInfo = props.mediaInfo;
  if (props.userData != null)
    userData = props.userData;

  if (props.mungeSDP != null)
    mungeSDP = props.mungeSDP;

  if (props.onconnectionstatechange != null)
    onconnectionstatechange = props.onconnectionstatechange;
  if (props.onstop != null)
    onstop = props.onstop;
  if (props.onerror != null)
    onerror = props.onerror;
  if (props.onstats != null)
  {
    statsInterval = setInterval(createOnStats(props.onstats),5000);
  }
  if (peerConnection == null)
  {
    if (wsConnection != null)
      wsConnection.close();
    wsConnection = null;

    console.log("FfmpegservicePeerConnectionPublish.start: wsURL:" + wsURL + " streamInfo:" + JSON.stringify(streamInfo));
    wsConnect(wsURL);
  }
  else
  {
    console.log('FfmpegservicePeerConnectionPublish.start: peerConnection already in use, not starting');
  }
}

function stop ()
{
  if (peerConnection != null)
    peerConnection.close();
  peerConnection = undefined;
  videoSender = undefined;
  audioSender = undefined;

  if (wsConnection != null)
    wsConnection.close();
  wsConnection = undefined;

  if (statsInterval != null)
  {
    clearInterval(statsInterval);
    statsInterval = undefined;
  }
  if (onstop != null)
  {
    onstop();
  }
}

function isStarted()
{
  return (peerConnection != null);
}

function errorHandler(error) {
  console.trace();
  if (onerror != null)
  {
    onerror(error);
  }
}

export default {
  connect: wsConnect,
  start: start,
  stop: stop,
  isStarted: isStarted,
  replaceTrack: replaceTrack,
  // pollAvailableStreams: pollAvailableStreams
};