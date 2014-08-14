module ApplicationHelper
  def clippy(text, bgcolor='#cccccc')
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
                  width="14"
                  height="14"
                  class="clippy"
                  id="clippy" >
          <param name="movie" value="#{asset_path('github-clippy.swf')}"/>
          <param name="allowScriptAccess" value="always" />
          <param name="quality" value="high" />
          <param name="scale" value="noscale" />
          <param NAME="FlashVars" value="id=clip_data&amp;copied=copied!&amp;copyto=copy to clipboard">
          <param name="bgcolor" value="#000000">
          <param name="wmode" value="opaque">
          <embed src="#{asset_path('github-clippy.swf')}"
                 width="14"
                 height="14"
                 name="clippy"
                 quality="high"
                 allowScriptAccess="always"
                 type="application/x-shockwave-flash"
                 pluginspage="http://www.macromedia.com/go/getflashplayer"
                 FlashVars="id=clip_data&amp;copied=copied!&amp;copyto=copy to clipboard"
                 bgcolor="#000000"
                 wmode="opaque"
          />
      </object>
    EOF
  end
end
