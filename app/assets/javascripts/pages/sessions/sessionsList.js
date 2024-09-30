$(document).ready(function(){

  document.addEventListener("click", e => {
    if(e.target && e.target.classList &&
        e.target.classList.contains("end_session_dashboard")) {
      if(confirm("Are you sure?")) {
        endSession(e.target.dataset.room_id)
      }
    }
  })

  if(document.querySelector(".end_session_page")){
    document.querySelector(".end_session_page").addEventListener("click", () => {
      if(confirm("Are you sure?")) {
        endSession(window.Immerss.session.room_id)
      }
    })
  }

})

function endSession(room_id) {
  fetch(`/api/v1/user/rooms/${room_id}`,{
    method: "PUT",
    headers: {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
      'Authorization':
          `Bearer ${window.getCookie('_unite_session_jwt')}`
      },
      body: JSON.stringify({room: {action: "stop"}})
  }).then(res => {
    window.flash("Session ended", "success")
    if(document.querySelector("#room_id_" + room_id)) {
      document.querySelector("#room_id_" + room_id).remove()
    }
    else {
      location.reload()
    }
  })
  .catch(error => {
    if(error && error.response && error.response.data && error.response.data.message) {
      window.flash(error.response.data.message)
    }
  })
}