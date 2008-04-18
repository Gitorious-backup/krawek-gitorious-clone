module CommentsHelper
  def render_comment_body(body, position)
    if body =~ /^(#(\d+))\b/
      comment_index = $2.to_i
      if comment_index > 0 && comment_index < position
        body = body.sub($1, %@<a href="#comment_#{comment_index}">#{$1}</a>@)
      end
    end
    simple_format(sanitize(body))
  end
end
