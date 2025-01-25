// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import LocationController from "controllers/location_controller"
eagerLoadControllersFrom("controllers", application)
application.register("location", LocationController)
