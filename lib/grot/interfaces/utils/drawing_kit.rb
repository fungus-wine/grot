#Gosu helpers

require 'gosu'

module Grot
  module Interfaces
    module DrawingKit
      # Circle and corner drawing constants
      CIRCLE_SEGMENTS = 32
      CORNER_SEGMENTS = 16
      MIN_RADIUS_FOR_ROUNDING = 2
      module_function  # This makes all methods both module and instance methods


      def draw_circle(x, y, radius, color, z = 0)
        num_segments = CIRCLE_SEGMENTS
        step = 360.0 / num_segments
        
        0.upto(num_segments) do |i|
          angle1 = i * step * Math::PI / 180
          angle2 = (i + 1) * step * Math::PI / 180
          
          x1 = x + radius * Math.cos(angle1)
          y1 = y + radius * Math.sin(angle1)
          x2 = x + radius * Math.cos(angle2)
          y2 = y + radius * Math.sin(angle2)
          
          Gosu.draw_triangle(x, y, color, x1, y1, color, x2, y2, color, z)
        end
      end

      # Draw a rounded rectangle
      def draw_rounded_rect(x, y, width, height, color, radius = 10, z = 0)
        # For very small radii, just draw a rectangle
        if radius <= MIN_RADIUS_FOR_ROUNDING
          Gosu.draw_rect(x, y, width, height, color, z)
          return
        end
        
        # Draw the center rectangle
        Gosu.draw_rect(
          x + radius, 
          y + radius, 
          width - 2 * radius, 
          height - 2 * radius, 
          color, 
          z
        )
        
        # Draw the four edge rectangles
        Gosu.draw_rect(x + radius, y, width - 2 * radius, radius, color, z)  # Top
        Gosu.draw_rect(x + radius, y + height - radius, width - 2 * radius, radius, color, z)  # Bottom
        Gosu.draw_rect(x, y + radius, radius, height - 2 * radius, color, z)  # Left
        Gosu.draw_rect(x + width - radius, y + radius, radius, height - 2 * radius, color, z)  # Right
        
        # Draw the four corner circles with more segments for smoother corners
        draw_rounded_corner(x + radius, y + radius, radius, :top_left, color, z)
        draw_rounded_corner(x + width - radius, y + radius, radius, :top_right, color, z)
        draw_rounded_corner(x + radius, y + height - radius, radius, :bottom_left, color, z)
        draw_rounded_corner(x + width - radius, y + height - radius, radius, :bottom_right, color, z)
      end

      # Draw a rounded corner for the rounded rectangle
      def draw_rounded_corner(center_x, center_y, radius, quadrant, color, z = 0)
        # Use consistent segment count for corners
        segments = CORNER_SEGMENTS
        angle_step = Math::PI / 2 / segments
        
        # Determine the starting angle for each quadrant
        start_angle = case quadrant
                      when :top_left     then Math::PI
                      when :top_right    then Math::PI * 3 / 2
                      when :bottom_left  then Math::PI / 2
                      when :bottom_right then 0
                      end
        
        # Create a fan of triangles for the quarter circle
        # Using a fan approach for more consistent alpha blending
        # Previous coordinate
        prev_x = center_x + radius * Math.cos(start_angle)
        prev_y = center_y + radius * Math.sin(start_angle)
        
        segments.times do |i|
          angle = start_angle + (i + 1) * angle_step
          
          # Current coordinate on the circle
          curr_x = center_x + radius * Math.cos(angle)
          curr_y = center_y + radius * Math.sin(angle)
          
          # Draw a single triangle
          Gosu.draw_triangle(
            center_x, center_y, color,
            prev_x, prev_y, color,
            curr_x, curr_y, color,
            z
          )
          
          # Update previous position
          prev_x = curr_x
          prev_y = curr_y
        end
      end

      # Draw a rounded rectangle outline
      def draw_rounded_rect_outline(x, y, width, height, color, radius = 10, z = 0, thickness = 1)
        # For very small radii, just draw a rectangle outline
        if radius <= MIN_RADIUS_FOR_ROUNDING
          # Draw four sides of rectangle
          Gosu.draw_rect(x, y, width, thickness, color, z) # Top
          Gosu.draw_rect(x, y + height - thickness, width, thickness, color, z) # Bottom
          Gosu.draw_rect(x, y, thickness, height, color, z) # Left
          Gosu.draw_rect(x + width - thickness, y, thickness, height, color, z) # Right
          return
        end
        
        # Draw the four edge rectangles for outline
        Gosu.draw_rect(x + radius, y, width - 2 * radius, thickness, color, z)  # Top
        Gosu.draw_rect(x + radius, y + height - thickness, width - 2 * radius, thickness, color, z)  # Bottom
        Gosu.draw_rect(x, y + radius, thickness, height - 2 * radius, color, z)  # Left
        Gosu.draw_rect(x + width - thickness, y + radius, thickness, height - 2 * radius, color, z)  # Right
        
        # Draw the four corner outlines
        draw_rounded_corner_outline(x + radius, y + radius, radius, :top_left, color, z, thickness)
        draw_rounded_corner_outline(x + width - radius, y + radius, radius, :top_right, color, z, thickness)
        draw_rounded_corner_outline(x + radius, y + height - radius, radius, :bottom_left, color, z, thickness)
        draw_rounded_corner_outline(x + width - radius, y + height - radius, radius, :bottom_right, color, z, thickness)
      end

      # Draw a rounded corner outline for the rounded rectangle
      def draw_rounded_corner_outline(center_x, center_y, radius, quadrant, color, z = 0, thickness = 1)
        segments = CORNER_SEGMENTS
        angle_step = Math::PI / 2 / segments
        
        # Determine the starting angle for each quadrant
        start_angle = case quadrant
                      when :top_left     then Math::PI
                      when :top_right    then Math::PI * 3 / 2
                      when :bottom_left  then Math::PI / 2
                      when :bottom_right then 0
                      end
        
        # Draw outline segments
        segments.times do |i|
          angle1 = start_angle + i * angle_step
          angle2 = start_angle + (i + 1) * angle_step
          
          # Outer edge
          x1_outer = center_x + radius * Math.cos(angle1)
          y1_outer = center_y + radius * Math.sin(angle1)
          x2_outer = center_x + radius * Math.cos(angle2)
          y2_outer = center_y + radius * Math.sin(angle2)
          
          # Inner edge
          inner_radius = radius - thickness
          x1_inner = center_x + inner_radius * Math.cos(angle1)
          y1_inner = center_y + inner_radius * Math.sin(angle1)
          x2_inner = center_x + inner_radius * Math.cos(angle2)
          y2_inner = center_y + inner_radius * Math.sin(angle2)
          
          # Draw quad for outline segment
          Gosu.draw_quad(
            x1_outer, y1_outer, color,
            x2_outer, y2_outer, color,
            x2_inner, y2_inner, color,
            x1_inner, y1_inner, color,
            z
          )
        end
      end
    end
  end
end