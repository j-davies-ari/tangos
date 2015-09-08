<%inherit file="/base.mako"/> \

<%def name="header()">${c.name}<small> N<sub>DM</sub>=${c.ndm}; N<sub>Bar</sub>=${c.nbar}</small></%def>

<%def name="breadcrumbs()">
${h.link_to('simdb',url(controller='sims',action='index'))} | ${h.link_to('simulation',url(controller='sims',action='showsim',id=c.simulation_id))}  | ${h.link_to('timestep',url(controller='sims',action='showstep',id=c.timestep_id))}
</%def>

<script type="text/javascript">


// solution to easily serialize/*de*serialize form data from
// http://stackoverflow.com/questions/1489486/jquery-plugin-to-serialize-a-form-and-also-restore-populate-the-form
$.fn.values = function(data) {
    var els = $(this).find(':input').get();

    if(typeof data != 'object') {
        // return all data
        data = {};

        $.each(els, function() {
            if (this.name && !this.disabled && (this.checked
                            || /select|textarea/i.test(this.nodeName)
                            || /text|hidden|password/i.test(this.type))) {
                data[this.name] = $(this).val();
            }
        });
        return data;
    } else {
        $.each(els, function() {
            if (this.name && data[this.name]) {
                if(this.type == 'checkbox' || this.type == 'radio') {
                    $(this).attr("checked", (data[this.name] == $(this).val()));
                } else {
                    $(this).val(data[this.name]);
                }
            }
        });
        return $(this);
    }
};

var storedState = {};
var objImg;
var storedBase;


function gograph(base_id)
{
    storedState = $('#myform').values();
    storedBase=base_id;
	var uri = $('#myform').serialize();
    loadImage(base_id+"?"+uri);
	$('#imgbox').empty().html("<img src='/spinner.gif' />&nbsp;Generating plot...");
	return true;
}

function loadImage(url) {
    objImg = new Image();
	objImg.src = url;
    objImg.onload = placeImage;
    objImg.onerror = placeImageError;
}

function placeImageError() {
    errorlink = '<a href="'+objImg.src+'" target="_blank">';
    $('#imgbox').empty().html("<h2>Sorry, there was an error generating your plot.</h2><p>Click "+errorlink+"here</a> for more information (opens in a new window)");

}

function placeImage() {
    $('#imgbox').empty()
    $('#imgbox').append(objImg);
    $('#imgbox').css('width',objImg.width);
}

function restoreFormState() {
    var newHalo = document.forms['myform']['halo_id'].value;
    var newTimestep = document.forms['myform']['timestep_id'].value;
    storedState['halo_id']=newHalo;
    storedState['timestep_id']=newTimestep;
    $("#myform").values(storedState);
}

function refreshImage() {
    // placeImage();
    if(objImg!=null) {
        $('#imgbox').append("<img src='/spinner.gif' />&nbsp;Updating plot...");

        loadImage(storedBase + "?" + $("#myform").serialize());
    }
}

var playdata;

function updateElementsFromResponse(data) {
    // $('#myform').replaceWith($(data).find('#myform'));

    playdata = data;
    $(".dynamic-update").each(function() {
        var elementId = '#'+this.id;
        var newData = $(data).find(elementId);
        console.info(elementId,newData);
        if(newData.size()>0) $(this).replaceWith(newData);
        else console.info("(no action: was null)");
    })

    restoreFormState();

    refreshImage();
    updatePositionsAfterScroll();
}
function timeNav(rel) {

    $("#navigation").html("<h2>Loading...</h2>");

    $.ajax({
           type: "GET",
           url: rel,
           beforeSend: function(){ },
           dataType: "html",
           success: updateElementsFromResponse
       });

    return false;
}

var interpret_name = "";
var interpret_axis ="";

function popupArrayInterpretationQuery(name,axis)
{
	interpret_name = name;
	interpret_axis = axis;
    console.info(name,axis);
	$('#popup_parent').css('visibility','visible');
	$('#interpret_box').css('visibility','visible');
	$('#whattoplot').val("");
	$('#whattoplot').focus();
}

function finishArrayInterpretationQuery()
{
	$('#popup_parent').css('visibility','hidden');
	$('#interpret_box').css('visibility','hidden');

    $("#myform input[name="+interpret_axis+"_array_element]").val($('#whattoplot').val());

}

function clearArrayInterpretation(axis) {
    $("#myform input[name=" + interpret_axis + "_array_element]").val("");
}


var scrollTop = {};

function initScrollOffsetData() {
    console.info("initScrollOffsetData");
    $(".keeponscreen").each(function() {
        if($(this).css('position')!='absolute') {
            // generate clone that keeps the space for this element
            var clone = $(this).clone();
            clone.removeClass("keeponscreen");
            clone.attr('id', clone.attr('id') + "-placeholder");
            clone.css('visibility', 'hidden');
            $(this).after(clone);
        }
        scrollTop[this.id]=this.getBoundingClientRect().top;

    });
}

function updatePositionsAfterScroll() {
    var windowTop = $(window).scrollTop();
    var current=0;
    $(".keeponscreen").each(function() {
        if(windowTop<scrollTop[this.id]-current) {
            $(this).css({position:"absolute",
                         top: scrollTop[this.id]});
        } else {
            $(this).css({position:"fixed",
                         top: current});
        }

        clone = $("#"+this.id+"-placeholder");
        if (clone!=null)
            clone.css({height: this.getBoundingClientRect().height+10});

        current = this.getBoundingClientRect().bottom
    });

}

function setupScrollAdjustment() {
    initScrollOffsetData();
    $(window).scroll(updatePositionsAfterScroll);
    updatePositionsAfterScroll();

}

function findInOtherSimulation() {
    timeNav(document.forms['select-othersimulation']['target_sim_id'].value);
}

var hasInitialized = false;

    $(function() {
        if(hasInitialized) return;
        hasInitialized=true;

        setupScrollAdjustment();

        $('.collapsibletable').click(function(){
            $(this).nextUntil('tr.header').slideToggle(1000);
        });

        $(".radio_scalar").click(function(){
            clearArrayInterpretation($(this)[0].name);
        });

        $(".radio_array").click(function(){
            console.info($(this));
            popupArrayInterpretationQuery($(this)[0].value, $(this)[0].name);
        });

     });

</script>




<div class="keeponscreen dynamic-update" id="navigation">
% for f in c.flash :
<p style="color:#f00;">${f}</p>
%endfor

<p>At z=${"%.2f"%c.timestep_z}, t=${c.timestep_t}; show this halo in another step (if available):
% for rel in ["earliest","-10","earlier","later","+10","latest"] :
%if rel=="-10" :
    <% linkurl = url(controller='sims', action='showhalo',id=c.this_id,rel="earlier",num=10)%>
%elif rel=="+10" :
    <% linkurl = url(controller='sims', action='showhalo',id=c.this_id,rel="later",num=10)%>
%else :
    <% linkurl = url(controller='sims', action='showhalo',id=c.this_id,rel=rel)%>
%endif
${h.link_to(rel,linkurl,onclick="return timeNav('"+linkurl+"');")}
%endfor
    | ${h.link_to('merger tree', url(controller='sims', action='mergertree', id=c.this_id))}
    </p>
    <form id="select-othersimulation">
        <label for="target_sim_id">Find the same halo in another simulation:</label>
<select name="target_sim_id" onchange="findInOtherSimulation();">
    %for sim_name, sim_id, ticked in c.sims:
    <option value="${url(controller='sims', action='showhalo', id=c.this_id, rel='insim',num=sim_id)}" ${'selected' if ticked else ''}>${sim_name}</option>
    %endfor

</select>
</form>

</div>

<div id="blackholes" class="dynamic-update">
${c.bh}
</div>

<p>

<div class="popup_parent" id="popup_parent"></div>
<div class="popup_box" id="interpret_box">
<p>You have selected to plot quantities from an array. Which element (starting at 0) do you want to plot?
You can also type + to extract the maximum, or - to extact the minimum.</p>
<form onsubmit="finishArrayInterpretationQuery(); return false;">
<input id="whattoplot" name="whattoplot" type="text" size=4>
<input type="submit" value="Continue">
</form>
</div>


<div id="imgbox" class="keeponscreen"></div>


<h2>Properties</h2>

<p>

<form id="myform" class="dynamic-update" action="${url(controller='plot', action='xy_img', id='txt')}" target="_blank">
<input type="hidden" name="timestep_id" value="${c.timestep_id}">
<input type="hidden" name="halo_id" value="${c.this_id}" >
    <input type="hidden" name="x_array_element" value="">
    <input type="hidden" name="y_array_element" value="">

<table>
<tr class="collapsibletable"><th>x</th><th>y</th><th>Plot</th><th>Property</th><th>Creator</th></tr>
<tr><td><input name="x" type="radio" value="t" checked/></td><td><input name="y" type="radio" value="t"/></td><td> </td><td>time =${c.timestep_t}</td> <td class="smallinfo"></td></tr>
<tr><td><input  name="x" type="radio" value="z"/></td><td><input name="y" type="radio" value="z"/></td><td> </td><td>redshift =${c.timestep_z}</td> <td class="smallinfo"></td></tr>
${c.props}
</table>
<div>


<h2>x vs y plot</h2>
<div>First select what your x and y variables are above, then choose:<br/>
<input type="radio" name="type" value="thishalo" checked>x vs y for this halo (or its major progenitors) over all time</input><br/>
<input type="radio" name="type" value="thistimestep">x vs y for all halos in this timestep</input>, optionally <input type="checkbox" name="nosubs" id="nosubs" checked>excluding subhalos</input><br/>
</div>
<div>
</div>
<div>
<input type="checkbox" name="xlog" id="xlog">X logarithmic</input><input type="checkbox" name="ylog" id="ylog">Y logarithmic</input>
</div><div>
<input type="submit" value="Plot!" onclick="gograph('${url(controller='plot', action='xy_img')}'); return false;" />
<input type="submit" href="gograph('); return false;" value="Get!" />
</div>
</div>

</form>


<div id="endlinks" class="dynamic-update">
% if len(c.dep_props)>0 :
<h2> Deprecated Properties</h2>
<table>
${c.dep_props}
</table>
% endif
<h2>Links</h2>
${c.links}
</div>