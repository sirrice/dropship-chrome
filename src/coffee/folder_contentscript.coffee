url = window.location.href
data = {message: "url", url: url}
chrome.extension.sendMessage data, (response) ->
