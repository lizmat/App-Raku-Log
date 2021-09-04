function setCookie(name, value) {
    document.cookie = name + "=" + value + ";path=/";
    return value;
}
function getCookie(cname) {
    let name = cname + "=";
    let decodedCookie = decodeURIComponent(document.cookie);
    let cookies = decodedCookie.split(';');
    for(let i = 0; cookies.length > i; i++) {
        let c = cookies[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            let cookie = c.substring(name.length, c.length);
            return cookie == "true"
              ? true
              : cookie == "false"
                ? false
                : cookie;
        }
    }
    return "";
}

var $gistTargets = getTargets();

var $filterMessagesByNick = getCookie("MessagesByNick");
var $filterMessagesByText = getCookie("MessagesByText");
var $filterExcludeByNick  = getCookie("ExcludeByNick")  // false;
var $filterExcludeByText  = getCookie("ExcludeByText")  // false;
var $showSystemMessages   = getCookie("SystemMessages") // false;
var $hideCommitMessages   = getCookie("CommitMessages") // false;
var $hideCameliaOutput    = getCookie("CameliaOutput")  // false;

var $showLeftSide  = getCookie("showLeftSide")  // false;
var $showRightSide = getCookie("showRightSide") // false;

/* Set the width of the sidebar to 300px and the left margin of the page content to 300px */

function setDisplay(id, state) {
    document.getElementById(id).style.display = state ? "block" : "none";
}
function toggleLeftSide() {
    $showLeftSide = setCookie('showLeftSide', !$showLeftSide);
    setDisplay('left-sidebar', $showLeftSide);
}
function toggleRightSide() {
    $showRightSide = setCookie('showRightSide', !$showRightSide);
    setDisplay('right-sidebar', $showRightSide);
}

function submitSearchIfEnter() {
    if (event.keyCode == 13 && okToSubmitSearch()) {
        document.getElementById('Search').submit();
    }
}
function submitSearchOnChannel(channel) {
    document.getElementById('SearchChannel').value = channel;
    document.getElementById('Search').submit();
}
function okToSubmitSearch() {
    return document.getElementById('SearchChannel').value;
}
function checkChannel() {
    if (okToSubmitSearch()) {
        return true;
    }
    document.getElementById('SearchChannel').focus();
    return false;
}

function scrollToBottom() {
    window.scrollTo(0, document.body.scrollHeight);
}

function hideChannelsWithoutTargets() {
    let items = document.querySelectorAll('li[id]');
    for (let i = 0; items.length > i; i++) {
        let item = items[i];
        if (!getTargets(item.getAttribute('id'))) {
            item.classList.add('is-hidden');
        }
    }
}

function getTargets(channel = '<.channel>') {
    return getCookie(channel + "Targets");
}

function setPrimaryByElement(element, primary) {
    if (primary) {
        element.classList.remove('is-primary');
    }
    else {
        element.classList.add('is-primary');
    }
}

function setButtons(name, state) {
    let buttons = document.querySelectorAll('button[id=' + name + ']');
    for (let i = 0; buttons.length > i; i++) {
        setPrimaryByElement(buttons[i], state);
    }
}

function setVisibilityByElement(element, visible) {
    if (visible) {
        element.classList.remove('is-hidden');
    }
    else {
        element.classList.add('is-hidden');
    }
}

function setVisibilityByName(name, visible) {
    let rows = document.getElementsByClassName(name);
    for (let i = 0; rows.length > i; i++) {
        setVisibilityByElement(rows[i], visible);
    }
}

function setCheckboxes(name, state) {
    let boxes = document.querySelectorAll('input[id=' + name + ']');
    for (let i = 0; boxes.length > i; i++) {
        boxes[i].checked = state;
    }
}

function visibilitySystemMessages(
  show = $showSystemMessages,
  global = true  // by default, set checkboxes + cookie as well
) {
    if (global) {
        $showSystemMessages = setCookie('SystemMessages', !!show);
        setCheckboxes('SystemMessages', $showSystemMessages);
    }
    setVisibilityByName("special-system", $showSystemMessages)
}

function visibilityCommitMessages(hidden = $hideCommitMessages) {
    $hideCommitMessages = setCookie('CommitMessages', !!hidden);
    setCheckboxes('CommitMessages', $hideCommitMessages);
    setVisibilityByName("special-commit", !$hideCommitMessages)
}

function visibilityCameliaOutput(hidden = $hideCameliaOutput) {
    $hideCameliaOutput = setCookie('CameliaOutput', !!hidden);
    setCheckboxes('CameliaOutput', $hideCameliaOutput);
    setVisibilityByName("special-camelia", !$hideCameliaOutput)
}

function updateFilter(name, value) {
    let inputs = document.querySelectorAll('input[id=' + name + ']');
    for (let i = 0; inputs.length > i; i++) {
        inputs[i].value = value;
    }
    return setCookie(name, value);
}

function containsAnyTexts(haystack, needles) {
    for (let i = 0; needles.length > i; i++) {
        let needle = needles[i].trim();
        if (needle) {
            if (haystack.toLowerCase().indexOf(needle) != -1) {
                return true;
            }
        }
        else {
            return true;
        }
    }
    return false;
}

function containsText(haystack, text) {
    let needle = text.trim();
    return needle
      ? haystack.toLowerCase().indexOf(needle) != -1
      : true;
}

function filterMessages(
  nick = $filterMessagesByNick,
  text = $filterMessagesByText
) {
    let columns = document.querySelectorAll('td[nick]');

    $filterMessagesByNick = updateFilter("MessagesByNick", nick);
    $filterMessagesByText = updateFilter("MessagesByText", text);
    setButtons('ExcludeByNick', $filterExcludeByNick);
    setButtons('ExcludeByText', $filterExcludeByText);

    if (nick || text) {
        visibilitySystemMessages(false, false);

        let lcNicks = nick.toLowerCase().split(',');
        let lcText  = text.toLowerCase();

        for (let i = 0; columns.length > i; i++) {
            let column = columns[i];
            let parent = column.parentElement;

            let nickOK = nick
              && containsAnyTexts(column.getAttribute("nick"),lcNicks)
                   == $filterExcludeByNick;
            let textOK = text
              && containsText(parent.cells[1].textContent, lcText)
                   == $filterExcludeByText;

            setVisibilityByElement(
              parent,
              (nick && text && nickOK && textOK)
                || (!nick && textOK)
                || (!text && nickOK)
            )
        }
    }

    else {
        for (let i = 0; columns.length > i; i++) {
            setVisibilityByElement(columns[i].parentElement, true)
        }
        visibilitySystemMessages();
        visibilityCommitMessages();
        visibilityCameliaOutput();
    }
}

function filterMessagesByNick(nick) {
    filterMessages(nick, $filterMessagesByText);
}
function filterMessagesByText(text) {
    filterMessages($filterMessagesByNick, text);
}

function filterExcludeByNick(button) {
    $filterExcludeByNick = setCookie(
      'ExcludeByNick',
      !!button.classList.contains('is-primary')
    );
    filterMessages();
}
function filterExcludeByText(button) {
    $filterExcludeByText = setCookie(
      'ExcludeByText',
      !!button.classList.contains('is-primary')
    );
    filterMessages();
}

function setGistTargets(targets = $gistTargets) {
    $gistTargets = setCookie('<.channel>Targets', targets);
    document.getElementById('Gist').href =
      '/<.channel>/gist.html?' + targets;
}

function elementOfTarget(element, target) {
    return document.querySelector(element + '[target="' + target + '"]');
}

function clearGistTargets() {
    setGistTargets("");
    markSelected();
}

function addVisibleTargets() {
    let newTargets = $gistTargets.split(',');;
    let haystack   = $gistTargets + ',';
    let trs = document.querySelectorAll('tr[target]');
    for (let i = 0; trs.length > i; i++) {
        let tr = trs[i];
        if (!tr.classList.contains('is-hidden')) {
            let target = tr.getAttribute('target');
            if (!haystack.includes(target + ',')) {
                setTargetSelectionState(target, true);
                newTargets.push(target);
            }
        }
    }
    setGistTargets(newTargets.sort().join(','));
}

function removeVisibleTargets() {
    let currentTargets = $gistTargets.split(",");
    let newTargets = [];
    for (let i = 0; currentTargets.length > i; i++) {
        let target = currentTargets[i];
        let tr     = elementOfTarget('tr', target);
        if (tr) {
            if (tr.classList.contains('is-hidden')) {
                newTargets.push(target);
            }
            else {
                setTargetSelectionState(target, false);
            }
        }
    }
    setGistTargets(newTargets.sort().join(','));
}

function setTargetSelectionState(target, on) {
    let tr = elementOfTarget('tr', target);
    if (tr) {
        if (on) {
            tr.classList.add('special-selected');
        }
        else {
            tr.classList.remove('special-selected');
        }
    }
    let option = elementOfTarget('a', target);
    if (option) {
        if (on) {
            option.classList.add('is-hidden');
            option.nextSibling.classList.remove('is-hidden');
        }
        else {
            option.classList.remove('is-hidden');
            option.nextSibling.classList.add('is-hidden');
        }
    }
}

function markSelected() {
    let links = document.querySelectorAll('a[target]');
    let haystack = $gistTargets + ',';
    for (let i = 0; links.length > i; i++) {
        let target = links[i].getAttribute('target');
        setTargetSelectionState(target, haystack.includes(target + ','));
    }
}

function removeTargetFromGist(link) {
    let target = link.previousSibling.getAttribute('target');
    let currentTargets = $gistTargets.split(',');
    let newTargets = [];
    let remove = false;
    for (let i = 0; currentTargets.length > i; i++) {
        let current = currentTargets[i];
        if (current) {
            if (current == target) {
                remove = true;
            }
            else {
                newTargets.push(current);
            }
        }
    }
    if (remove) {
        setTargetSelectionState(target, false);
    }
    setGistTargets(newTargets.sort().join(','));
}

function addTargetToGist(link) {
    let target = link.getAttribute('target');
    let currentTargets = $gistTargets.split(',');
    let newTargets = [];
    let add = true;
    for (let i = 0; currentTargets.length > i; i++) {
        let current = currentTargets[i];
        if (current) {
            if (current == target) {
                add = false;
            }
            else {
                newTargets.push(current);
            }
        }
    }
    if (add) {
        setTargetSelectionState(target, true);
        newTargets.push(target);
    }
    setGistTargets(newTargets.sort().join(','));
}
