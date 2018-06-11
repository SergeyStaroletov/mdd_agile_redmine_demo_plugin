# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2018 RedmineUP
# http://www.redmineup.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

class AgileBoardsController < ApplicationController
  unloadable

  menu_item :agile

  before_action :find_issue, :only => [:update, :issue_tooltip, :inline_comment]
  before_action :find_optional_project, :only => [:index, :create_issue]

  helper :issues
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :timelog
  include RedmineAgile::AgileHelper

#все нужные хелперы уже подключены



#
#генерация bpmn файла
#
  def bpmn


#обход всех issues (issues_controller)
    retrieve_query
    if @query.valid?
	@issues = @query.issues(:limit => Setting.issues_export_limit.to_i)     

	#сюда пишем результат
	out_str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:bpmndi=\"http://www.omg.org/spec/BPMN/20100524/DI\" xmlns:omgdc=\"http://www.omg.org/spec/DD/20100524/DC\" xmlns:omgdi=\"http://www.omg.org/spec/DD/20100524/DI\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" targetNamespace=\"\" xsi:schemaLocation=\"http://www.omg.org/spec/BPMN/20100524/MODEL http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd\">" + "<collaboration id=\"Collaboration_1\"><participant id=\"Participant_1\" name=\"feature1\" processRef=\"Process_1\" /></collaboration><process id=\"Process_1\"><startEvent id=\"Task_0\"><outgoing>SequenceFlow_0</outgoing></startEvent>"
	num = 1 	
	#итератор в обратном порядке
	@issues.reverse_each {
		|issue| out_str += "<task id=\"Task_" + num.to_s + "\" name=\"" + issue.subject +  "\"><incoming>SequenceFlow_" + num.to_s + "</incoming><outgoing>SequenceFlow_" + (num + 1).to_s + "</outgoing></task>" + "<sequenceFlow id=\"SequenceFlow_" + num.to_s  + "\" sourceRef=\"Task_" + num.to_s + "\" targetRef=\"Task_" + (num + 1).to_s + "\" />"

		num = num + 1		
		#out_str += issue.subject + "<br>"
	}

	out_str += "<endEvent id=\"Task_" + num.to_s + "\"><incoming>SequenceFlow_" + num.to_s + "</incoming></endEvent></process>"


	#размеры
	out_str +=  "<bpmndi:BPMNDiagram id=\"sid-74620812-92c4-44e5-949c-aa47393d3830\"><bpmndi:BPMNPlane id=\"sid-cdcae759-2af7-4a6d-bd02-53f3352a731d\" bpmnElement=\"Collaboration_1\"><bpmndi:BPMNShape id=\"Participant_1_di\" bpmnElement=\"Participant_1\"><omgdc:Bounds x=\"150\" y=\"39\" width=\"810\" height=\"356\" /></bpmndi:BPMNShape><bpmndi:BPMNShape id=\"Task_0_di\" bpmnElement=\"Task_0\"><omgdc:Bounds x=\"212\" y=\"109\" width=\"36\" height=\"36\" /></bpmndi:BPMNShape>"
	x = 250
	num = 1
	@issues.reverse_each {
		|issue| out_str += "<bpmndi:BPMNShape id=\"Task_" + num.to_s + "_di\" bpmnElement=\"Task_" + num.to_s + "\"><omgdc:Bounds x=\"" + x.to_s + "\" y=\"87\" width=\"100\" height=\"80\" /></bpmndi:BPMNShape>"
		x = x + 100
		num = num + 1		
		#out_str += issue.subject + "<br>"
	}
	#fin
	out_str += "<bpmndi:BPMNShape id=\"Task_" + num.to_s + "_di\" bpmnElement=\"Task_" + num.to_s + "\"><omgdc:Bounds x=\"" + x.to_s + "\" y=\"87\" width=\"100\" height=\"80\" /></bpmndi:BPMNShape>"

	#надо еще для связей
	#<bpmndi:BPMNEdge id="SequenceFlow_0_di" bpmnElement="SequenceFlow_0">
        #<omgdi:waypoint x="248" y="127" />
        #<omgdi:waypoint x="301" y="127" />


	out_str += "</bpmndi:BPMNPlane><bpmndi:BPMNLabelStyle id=\"sid-e0502d32-f8d1-41cf-9c4a-cbb49fecf581\"><omgdc:Font name=\"Arial\" size=\"11\" isBold=\"false\" isItalic=\"false\" isUnderline=\"false\" isStrikeThrough=\"false\" /></bpmndi:BPMNLabelStyle><bpmndi:BPMNLabelStyle id=\"sid-84cb49fd-2f7c-44fb-8950-83c3fa153d3b\"><omgdc:Font name=\"Arial\" size=\"12\" isBold=\"false\" isItalic=\"false\" isUnderline=\"false\" isStrikeThrough=\"false\" /></bpmndi:BPMNLabelStyle></bpmndi:BPMNDiagram>"


	out_str += "</definitions>"

	#вывод в стиле php echo (антипаттерн)
    	render html: out_str.html_safe

    #при багах	
    else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404

  end





  def index
    retrieve_agile_query
    if @query.valid?
      @issues = @query.issues
      @issue_board = @query.issue_board
      @board_columns = @query.board_statuses

      respond_to do |format|
        format.html { render :template => 'agile_boards/index', :layout => !request.xhr? }
        format.js
      end
    else
      respond_to do |format|
        format.html { render(:template => 'agile_boards/index', :layout => !request.xhr?) }
        format.js
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update
    (render_403; return false) unless @issue.editable?
    retrieve_agile_query_from_session
    old_status = @issue.status
    @issue.init_journal(User.current)
    @issue.safe_attributes = auto_assign_on_move? ? params[:issue].merge(:assigned_to_id => User.current.id) : params[:issue]
    checking_params = params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash : params
    saved = checking_params['issue'] && checking_params['issue'].inject(true) do |total, attribute|
      if @issue.attributes.include?(attribute.first)
        total &&= @issue.attributes[attribute.first].to_i == attribute.last.to_i
      else
        total &&= true
      end
    end
    call_hook(:controller_agile_boards_update_before_save, { :params => params, :issue => @issue})
    @update = true
    if saved && @issue.save
      call_hook(:controller_agile_boards_update_after_save, { :params => params, :issue => @issue})
      AgileData.transaction do
        Issue.eager_load(:agile_data).find(params[:positions].keys).each do |issue|
          issue.agile_data.position = params[:positions][issue.id.to_s]['position']
          issue.agile_data.save
        end
      end if params[:positions]

      @inline_adding = params[:issue][:notes] || nil

      respond_to do |format|
        format.html { render(:partial => 'issue_card', :locals => {:issue => @issue}, :status => :ok, :layout => nil) }
      end
    else
      respond_to do |format|
        messages = @issue.errors.full_messages
        messages = [l(:text_agile_move_not_possible)] if messages.empty?
        format.html {
          render :json => messages, :status => :fail, :layout => nil
        }
      end
    end
  end

  def issue_tooltip
    render :partial => 'issue_tooltip'
  end

  def inline_comment
    render 'inline_comment', :layout => nil
  end

  private

  def auto_assign_on_move?
    RedmineAgile.auto_assign_on_move? && @issue.assigned_to.nil? &&
      !params[:issue].keys.include?('assigned_to_id') &&
      @issue.status_id != params[:issue]['status_id'].to_i
  end

end
