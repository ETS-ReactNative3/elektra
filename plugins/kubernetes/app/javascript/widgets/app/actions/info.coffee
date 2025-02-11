import * as constants from "../constants"
import {ajaxHelper} from "./ajax_helper"

# -------------- KUBERNIKUS INFO ---------------
requestInfo = () ->
  type: constants.REQUEST_INFO

requestInfoFailure = (error) ->
  type: constants.REQUEST_INFO_FAILURE
  error: error

receiveInfo = (data) ->
  type: constants.RECEIVE_INFO
  info: data

setClusterFormDefaultVersion = (data) ->
  type: constants.SET_CLUSTER_FORM_DEFAULT_VERSION
  info: data

loadInfo = (options) ->
  (dispatch, getState) ->

    info = getState().info
    return if info? && info.error == ""  # don't fetch if we already have the Info

    dispatch(requestInfo())

    ajaxHelper.get "/info",
      contentType: 'application/json'
      success: (data, textStatus, jqXHR) ->
        dispatch(receiveInfo(data))
        if options.workflow == 'new'
          dispatch(setClusterFormDefaultVersion(data))
      error: ( jqXHR, textStatus, errorThrown) ->
        errorMessage =  if typeof jqXHR.responseJSON == 'object'
                            jqXHR.responseJSON.message
                        else jqXHR.responseText
        dispatch(requestInfoFailure(errorMessage))
        # retry up to 20 times
        if getState().info.errorCount <= 20
          dispatch(loadInfo(options))

# export
export {
  loadInfo
}

