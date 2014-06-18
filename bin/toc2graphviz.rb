#!/usr/bin/env ruby

require 'graphviz'

class Topic
  attr_accessor :index, :level, :label, :x , :y 
  def initialize(level,index,label)
    @level, @index, @label = level, index, label
  end

  def rank # sibling order
    index.split(/\./).last.to_i - 1 #TODO
  end

  def parent_index
    *body, rank = index.split(/\./)
    body.join "."
  end

  def to_s
    [@index, @label].join "--"
  end
end

raw = ARGV[0]


lines = File.open(raw)
            .readlines
            .select {|i| i.start_with?("=")}
            .map {|i| a,b,c = i.partition(/\=+/); [b.length - 1,c]}


# give a index to each label
# e.g. 1.2.4 balloon
#      1.2.4.1 foot
previous = 0
parents = {0 => 0}
brothers = Hash.new(1)
x = lines.map do |level,label|
  if level == previous + 1
     parents[level] = [parents[previous],brothers[previous]].join "."
     brothers[level] = 1
  else 
     brothers[level] += 1
  end
  previous = level
  index =  [parents[level], brothers[level] ].join "."
  Topic.new( level,index, label.strip)
end


def shape(level)
  case level
  when 0..1
    :circle
  when 2
    :ellipse
  when 3
    :underline
  when 4
    :none
  else
    :none
  end
end

def height(level)
  case level
  when 0
    3
  when 1
    1
  when 2..3
    1
  when 4
    1
  else
    30
  end
end

def color(level)
  case level
  when 0
    :yellow
  when 1
    :orange
  when 2..3
    :lawngreen
  when 4
    :blue
  else
    :none
  end
end

def style(level)
 case level
 when 0..2
  :filled
when 3..5
  :none
 end
end


def nodes_per_level(x)
  x.group_by {|i| i.level }.map {|k,v| [k, v.count]}
end

def fontsize(level)
  24
end

def fontcolor(level)
  level > 2 ? :green : :black
end

def assign_node_positions(x, radius)
  x.group_by {|i| i.level}.each do |level,topics|
    r = radius * level ** 1.4
    n = topics.count
    angles = n < 10 ? equally_spaced(n) : equally_spaced_vertically(n)
    topics.zip(angles) do |topic,angle|
      topic.x = (r * Math.cos(angle)).to_i
      topic.y = (1 * r * Math.sin(angle)).to_i
    end
  end
end

def quote( *b )
  %Q(#{b.join(",")}) 
end

def equally_spaced(n)
   delta = Math::PI * 2 / n
  (0..n).map {|i| i * delta }
end


def equally_spaced_vertically(n)
  result = []
  dv = Rational(4,n)
  v = 0
  (0...n).map do |i|
    v = i * dv
    quadrant = v.to_i
    case quadrant
    when 0
       y = v
    when 1
      y = 2 - v
    when 2
      y =  2 - v
    when 3
      y =  v - 4
    end
    x = Math.sqrt( 1 - y ** 2)
    x *= -1 if (1..2).include?(quadrant)
    Math.atan2(y,x)
  end
end



# print a circle at the centre
def to_circle(x, width, height)
  gv = GraphViz.new(:G, :type => :digraph )
  gv.graph[  concentrate: true]
  gv.edge[arrowhead: :none, fontcolor: :grey]
  topics = x.select {|i| i.level <= 5}
  assign_node_positions(topics,200)
  topics.each do |topic|
    position = quote(topic.x,topic.y)
    level = topic.level
    gv.add_nodes(topic.index, { height: height(level), fontcolor: fontcolor(level), fontsize: fontsize(level) , label:  topic.label, shape: shape(level), style: style(level), color: color(level),  pos: position })
    gv.add_edges(topic.parent_index, topic.index) if topic.level > 0
  end
  gv.output(svg: "roadmap.svg", use: "neato", no_layout: 1, scale: 72 )
end



to_circle(x,0,0)


